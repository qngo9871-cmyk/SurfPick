import WidgetKit
import SwiftUI
import CoreLocation
import SurfShared

// MARK: - Timeline Entry

struct SurfPickEntry: TimelineEntry {
    let date: Date
    let topBreak: TopBreakSnapshot?

    /// State the widget renders. Mirrors AppState but simplified.
    enum State {
        case loaded(TopBreakSnapshot)
        case noLocation
        case noData
    }

    var state: State {
        if let b = topBreak {
            return .loaded(b)
        } else {
            return .noData
        }
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
        SurfPickEntry(
            date: Date(),
            topBreak: TopBreakSnapshot(
                name: "Lennox Head",
                distanceText: "5.2 km away",
                waveSummary: "1.4m · 11s · 8k SW",
                ratingRaw: Rating.good.rawValue
            )
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
                return SurfPickEntry(date: Date(), topBreak: snapshot)
            }
        } catch {
            // fall through
        }

        return SurfPickEntry(date: Date(), topBreak: nil)
    }
}

// MARK: - Widget View

struct SurfPickWidgetView: View {
    let entry: SurfPickEntry

    var body: some View {
        switch entry.state {
        case .loaded(let snapshot):
            loadedView(snapshot)
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
        )
    )
    SurfPickEntry(date: .now, topBreak: nil)
}
