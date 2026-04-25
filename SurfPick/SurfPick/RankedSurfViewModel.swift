import Foundation
import Combine
import CoreLocation
import SurfShared

/// A surf break with its current conditions and overall rating, used by RankedListView.
struct RankedBreak: Identifiable {
    let nearby: NearbySpot
    let conditions: SurfConditions?
    let rating: Rating?

    var id: String { nearby.id }
}

@MainActor
final class RankedSurfViewModel: ObservableObject {
    @Published var state: AppState = .idle
    @Published var rankedBreaks: [RankedBreak] = []
    @Published var lastUpdated: Date?
    @Published var isRefreshing: Bool = false

    private let locationManager = LocationManager()
    private let spotFinder = SurfSpotFinder()
    private let forecastService = ForecastService()

    /// Number of nearest spots to fetch and rank. v1 uses 10.
    private let spotCount = 10

    // MARK: - Public

    func fetch() {
        Task { await performFetch(forceRefresh: false) }
    }

    func refresh() {
        Task { await performFetch(forceRefresh: true) }
    }

    func confirmLocationPermission() {
        // User pressed Continue on the explainer — now actually request location,
        // bypassing the .notDetermined → explainer guard.
        state = .locating
        Task { await performFetch(forceRefresh: true) }
    }

    // MARK: - Internal

    private func performFetch(forceRefresh: Bool) async {
        // Show pre-permission explainer if location permission hasn't been requested yet
        if locationManager.authorizationStatus == .notDetermined && !forceRefresh {
            state = .locationExplainer
            return
        }

        // If we already have data and this is a refresh, keep showing the old data while loading
        if forceRefresh && !rankedBreaks.isEmpty {
            isRefreshing = true
        } else if rankedBreaks.isEmpty {
            // Try cache for instant first paint
            if let cached = Self.loadCachedResult() {
                rankedBreaks = cached.breaks
                lastUpdated = cached.timestamp
                state = .loaded
            } else {
                state = .locating
            }
        }

        do {
            let location = try await locationManager.requestLocation(forceFresh: forceRefresh)
            let spots = spotFinder.findNearest(to: location, count: spotCount)

            guard !spots.isEmpty else {
                if rankedBreaks.isEmpty { state = .errorLocation }
                isRefreshing = false
                return
            }

            if rankedBreaks.isEmpty { state = .fetching }

            // Fetch conditions for all spots in parallel
            let ranked = await fetchAllConditions(for: spots)

            // Sort: best rating first, ties broken by distance.
            // Spots that fail to load (rating == nil) go to the end.
            let sorted = ranked.sorted { a, b in
                switch (a.rating, b.rating) {
                case (let r1?, let r2?):
                    if r1 != r2 { return r1 < r2 }   // .good < .ok < .poor — good wins
                    return a.nearby.distanceKm < b.nearby.distanceKm
                case (.some, .none): return true
                case (.none, .some): return false
                case (.none, .none):
                    return a.nearby.distanceKm < b.nearby.distanceKm
                }
            }

            rankedBreaks = sorted
            lastUpdated = Date()
            state = .loaded
            isRefreshing = false

            Self.saveCachedResult(breaks: sorted, timestamp: Date())
        } catch is LocationError {
            isRefreshing = false
            if rankedBreaks.isEmpty { state = .errorLocation }
        } catch {
            isRefreshing = false
            if rankedBreaks.isEmpty { state = .errorNetwork }
        }
    }

    private func fetchAllConditions(for spots: [NearbySpot]) async -> [RankedBreak] {
        await withTaskGroup(of: (Int, RankedBreak).self) { group in
            for (idx, nearby) in spots.enumerated() {
                group.addTask { [forecastService] in
                    do {
                        let cond = try await forecastService.fetchConditions(
                            latitude: nearby.spot.latitude,
                            longitude: nearby.spot.longitude
                        )
                        let rating = ConditionsCalculator.overallRating(
                            conditions: cond,
                            idealWindBearing: nearby.spot.idealWindBearing
                        )
                        return (idx, RankedBreak(nearby: nearby, conditions: cond, rating: rating))
                    } catch {
                        return (idx, RankedBreak(nearby: nearby, conditions: nil, rating: nil))
                    }
                }
            }

            var results: [(Int, RankedBreak)] = []
            for await item in group { results.append(item) }
            results.sort { $0.0 < $1.0 }
            return results.map { $0.1 }
        }
    }

    // MARK: - Disk Cache

    private static let cacheFile: URL? = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask).first?
        .appendingPathComponent("surfPickCache.json")

    private struct CachedBreak: Codable {
        let name: String
        let latitude: Double
        let longitude: Double
        let idealWindBearing: Int
        let distanceKm: Double
        let waveHeight: Double?
        let wavePeriod: Int?
        let waveDirection: Double?
        let windSpeed: Int?
        let windDirection: Double?
        let ratingRaw: Int?
    }

    private struct CachedPayload: Codable {
        let timestamp: Date
        let breaks: [CachedBreak]
    }

    private static func saveCachedResult(breaks: [RankedBreak], timestamp: Date) {
        let cached = breaks.map { item in
            CachedBreak(
                name: item.nearby.spot.name,
                latitude: item.nearby.spot.latitude,
                longitude: item.nearby.spot.longitude,
                idealWindBearing: item.nearby.spot.idealWindBearing,
                distanceKm: item.nearby.distanceKm,
                waveHeight: item.conditions?.waveHeight,
                wavePeriod: item.conditions?.wavePeriod,
                waveDirection: item.conditions?.waveDirection,
                windSpeed: item.conditions?.windSpeed,
                windDirection: item.conditions?.windDirection,
                ratingRaw: item.rating?.rawValue
            )
        }
        let payload = CachedPayload(timestamp: timestamp, breaks: cached)
        guard let cacheFile = cacheFile else { return }
        try? JSONEncoder().encode(payload).write(to: cacheFile)
    }

    private static func loadCachedResult() -> (breaks: [RankedBreak], timestamp: Date)? {
        guard let cacheFile = cacheFile,
              let data = try? Data(contentsOf: cacheFile),
              let payload = try? JSONDecoder().decode(CachedPayload.self, from: data),
              abs(payload.timestamp.timeIntervalSinceNow) < 3600 else {
            return nil
        }

        let breaks: [RankedBreak] = payload.breaks.map { item in
            let spot = SurfSpot(
                name: item.name,
                latitude: item.latitude,
                longitude: item.longitude,
                idealWindBearing: item.idealWindBearing
            )
            let nearby = NearbySpot(spot: spot, distanceKm: item.distanceKm)
            let conditions: SurfConditions?
            if let wh = item.waveHeight,
               let wp = item.wavePeriod,
               let wd = item.waveDirection,
               let ws = item.windSpeed,
               let wdir = item.windDirection {
                conditions = SurfConditions(
                    waveHeight: wh,
                    wavePeriod: wp,
                    waveDirection: wd,
                    windSpeed: ws,
                    windDirection: wdir,
                    tideInfo: nil
                )
            } else {
                conditions = nil
            }
            let rating = item.ratingRaw.flatMap { Rating(rawValue: $0) }
            return RankedBreak(nearby: nearby, conditions: conditions, rating: rating)
        }

        return (breaks, payload.timestamp)
    }
}
