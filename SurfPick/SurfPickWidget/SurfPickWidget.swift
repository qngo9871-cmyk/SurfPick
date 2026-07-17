import WidgetKit
import SwiftUI
import CoreLocation
import StoreKit
import SurfShared

// MARK: - Pro entitlement

/// Duplicates `ProAccess.isPro()` from the main app target (`FreeRevealStore.swift`).
/// The widget extension is a separate synchronized-folder target and doesn't share
/// that file's target membership, so this is a standalone StoreKit entitlement
/// check rather than a shared import — same product ID, same logic.
enum WidgetProAccess {
    static let proProductID = "com.quyenngo.surfpick.pro"

    static func isPro() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               tx.productID == proProductID, tx.revocationDate == nil {
                return true
            }
        }
        return false
    }
}

// MARK: - Timeline Entry

struct SurfPickEntry: TimelineEntry {
    let date: Date
    let topBreak: TopBreakSnapshot?
    let isPro: Bool

    /// State the widget renders. Mirrors AppState but simplified.
    enum State {
        case loaded(TopBreakSnapshot)
        case locked
        case noLocation
        case noData
    }

    /// Free users never see the actual top-pick answer here — that's the same
    /// thing the in-app paywall gates behind the one-time Pro unlock. Only show
    /// the locked state when there's actually something to hide.
    var state: State {
        guard let b = topBreak else { return .noData }
        return isPro ? .loaded(b) : .locked
    }
}

/// Lightweight snapshot used to render the widget — avoids holding heavy types.
struct TopBreakSnapshot {
    let name: String
    let distanceText: String
    let waveSummary: String
    let ratingRaw: Int

    var rating: Rating? { Rating(rawValue: ratingRaw) }
}

// MARK: - Provider

struct SurfPickProvider: TimelineProvider {
    func placeholder(in context: Context) -> SurfPickEntry {
        // Gallery preview always shows the loaded look (WidgetKit redacts it
        // automatically as a loading skeleton) — the real entitlement check
        // happens in fetchTopBreak() for the actual timeline.
        SurfPickEntry(
            date: Date(),
            topBreak: TopBreakSnapshot(
                name: "Lennox Head",
                distanceText: "5.2 km away",
                waveSummary: "1.4m · 11s · 8k SW",
                ratingRaw: Rating.good.rawValue
            ),
            isPro: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SurfPickEntry) -> Void) {
        // Use placeholder data for fast snapshot rendering (gallery preview, etc.)
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SurfPickEntry>) -> Void) {
        Task {
            let entry = await fetchTopBreak()
            // Refresh every 30 minutes — surf conditions change but not minute-to-minute
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    /// Find nearest spot, fetch its conditions, return as widget entry.
    private func fetchTopBreak() async -> SurfPickEntry {
        let isPro = await WidgetProAccess.isPro()
        let locationManager = LocationManager()
        let spotFinder = SurfSpotFinder()
        let forecastService = ForecastService()

        // Widget extensions can use a cached location even without active permission grant,
        // but a fresh fetch may fail silently if backgrounded. Fall back to nil on any error.
        do {
            let location = try await locationManager.requestLocation()
            let spots = spotFinder.findNearest(to: location, count: 10)

            // Fetch all in parallel, find the best
            let scored: [(NearbySpot, SurfConditions, Rating)] = await withTaskGroup(of: (NearbySpot, SurfConditions, Rating)?.self) { group in
                for spot in spots {
                    group.addTask {
                        do {
                            let cond = try await forecastService.fetchConditions(
                                latitude: spot.spot.latitude,
                                longitude: spot.spot.longitude
                            )
                            let rating = ConditionsCalculator.overallRating(
                                conditions: cond,
                                idealWindBearing: spot.spot.idealWindBearing
                            )
                            return (spot, cond, rating)
                        } catch {
                            return nil
                        }
                    }
                }
                var results: [(NearbySpot, SurfConditions, Rating)] = []
                for await item in group {
                    if let item { results.append(item) }
                }
                return results
            }

            // Sort: best rating first, ties broken by distance
            let sorted = scored.sorted { a, b in
                if a.2 != b.2 { return a.2 < b.2 }
                return a.0.distanceKm < b.0.distanceKm
            }

            if let top = sorted.first {
                let snapshot = TopBreakSnapshot(
                    name: top.0.spot.name,
                    distanceText: top.0.formattedDistance,
                    waveSummary: "\(String(format: "%.1f", top.1.waveHeight))m · \(top.1.wavePeriod)s · \(top.1.windSpeed)k \(compassDirection(from: top.1.windDirection))",
                    ratingRaw: top.2.rawValue
                )
                return SurfPickEntry(date: Date(), topBreak: snapshot, isPro: isPro)
            }
        } catch {
            // fall through
        }

        return SurfPickEntry(date: Date(), topBreak: nil, isPro: isPro)
    }
}

// MARK: - Widget View

struct SurfPickWidgetView: View {
    let entry: SurfPickEntry

    var body: some View {
        switch entry.state {
        case .loaded(let snapshot):
            loadedView(snapshot)
        case .locked:
            lockedView
        case .noLocation, .noData:
            emptyView
        }
    }

    @ViewBuilder
    private func loadedView(_ snapshot: TopBreakSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                if let rating = snapshot.rating {
                    Circle()
                        .fill(ratingColor(rating))
                        .frame(width: 14, height: 14)
                }
                Text("Top pick")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }
            Text(snapshot.name)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(snapshot.distanceText)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 2)
            Text(snapshot.waveSummary)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.vertical, 2)
    }

    // Non-Pro users see a lock prompt instead of the actual best-break answer —
    // that answer is exactly what the in-app paywall gates behind Pro.
    private var lockedView: some View {
        VStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Unlock Pro")
                .font(.caption.weight(.medium))
                .multilineTextAlignment(.center)
            Text("to see the best spot")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 6) {
            Image(systemName: "water.waves")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Open Surf Pick")
                .font(.caption.weight(.medium))
                .multilineTextAlignment(.center)
            Text("to find nearby spots")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func ratingColor(_ rating: Rating) -> Color {
        switch rating {
        case .good: return Color(red: 52/255, green: 199/255, blue: 89/255)
        case .ok:   return Color(red: 255/255, green: 149/255, blue: 0/255)
        case .poor: return Color(red: 255/255, green: 59/255, blue: 48/255)
        }
    }
}

// MARK: - Widget configuration

struct SurfPickWidget: Widget {
    let kind: String = "SurfPickWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SurfPickProvider()) { entry in
            SurfPickWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Top Surf Pick")
        .description("The best surf spot near you right now.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

#Preview(as: .systemSmall) {
    SurfPickWidget()
} timeline: {
    SurfPickEntry(
        date: .now,
        topBreak: TopBreakSnapshot(
            name: "Lennox Head",
            distanceText: "5.2 km away",
            waveSummary: "1.4m · 11s · 8k SW",
            ratingRaw: Rating.good.rawValue
        ),
        isPro: true
    )
    SurfPickEntry(
        date: .now,
        topBreak: TopBreakSnapshot(
            name: "Lennox Head",
            distanceText: "5.2 km away",
            waveSummary: "1.4m · 11s · 8k SW",
            ratingRaw: Rating.good.rawValue
        ),
        isPro: false
    )
    SurfPickEntry(date: .now, topBreak: nil, isPro: false)
}
