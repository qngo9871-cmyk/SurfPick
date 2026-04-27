import SwiftUI
import UIKit
import Charts
import SurfShared

struct BreakDetailView: View {
    let `break`: RankedBreak

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(alignment: .top, spacing: 14) {
                    if let rating = `break`.rating {
                        RatingDot(rating: rating, size: 44)
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 44, height: 44)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(`break`.nearby.spot.name)
                            .font(.largeTitle.bold())
                            .lineLimit(2)
                        Text(`break`.nearby.formattedDistance)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Conditions cards
                if let c = `break`.conditions {
                    VStack(spacing: 12) {
                        DetailCard(
                            icon: "water.waves",
                            title: "Wave",
                            primary: "\(String(format: "%.1f", c.waveHeight))m",
                            secondary: "\(c.wavePeriod)s period · \(compassDirection(from: c.waveDirection))"
                        )

                        let windType = ConditionsCalculator.windType(
                            windDirection: c.windDirection,
                            idealWindBearing: `break`.nearby.spot.idealWindBearing
                        )
                        DetailCard(
                            icon: "wind",
                            title: "Wind",
                            primary: "\(c.windSpeed) km/h",
                            secondary: "\(compassDirection(from: c.windDirection)) · \(ConditionsCalculator.windTypeLabel(windType))"
                        )

                        if let tide = c.tideInfo {
                            TideCard(tide: tide)
                        }
                    }
                    .padding(.horizontal, 16)
                } else {
                    Text("Conditions data unavailable. Try refreshing on the main screen.")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                }

                Spacer(minLength: 16)

                // Directions actions
                VStack(spacing: 10) {
                    Button {
                        MapsHandoff.openDirections(
                            to: `break`.nearby.spot.coordinate,
                            label: `break`.nearby.spot.name
                        )
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                            Text("Get Directions")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    HStack(spacing: 10) {
                        Button {
                            MapsHandoff.openDirections(
                                to: `break`.nearby.spot.coordinate,
                                label: `break`.nearby.spot.name,
                                using: .google
                            )
                        } label: {
                            Text("Open in Google Maps")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            MapsHandoff.openDirections(
                                to: `break`.nearby.spot.coordinate,
                                label: `break`.nearby.spot.name,
                                using: .apple
                            )
                        } label: {
                            Text("Open in Apple Maps")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal, 16)

                // Report wrong location
                Button {
                    openReportEmail()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.bubble")
                        Text("Report wrong location")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func openReportEmail() {
        let spot = `break`.nearby.spot
        let name = spot.name

        let subject = "Surf Pick — Wrong location: \(name)"
        let body = """
        Spot: \(name)
        Claimed coords: \(spot.latitude), \(spot.longitude)

        Correct coords (paste from Google/Apple Maps long-press):


        Notes (optional):


        ---
        Surf Pick \(Bundle.main.appVersionString)
        """

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "qngo9871@gmail.com"
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        if let url = components.url {
            UIApplication.shared.open(url)
        }
    }

}

private struct TideLevelPoint: Identifiable {
    let id: Int
    let hour: Int
    let level: Double
}

struct TideCard: View {
    let tide: TideInfo

    private var now: Date { Date() }

    private var currentX: Double {
        let cal = Calendar.current
        let h = cal.component(.hour, from: now)
        let m = cal.component(.minute, from: now)
        return Double(h) + Double(m) / 60.0
    }

    private var points: [TideLevelPoint] {
        tide.hourlyLevels
            .sorted { $0.hour < $1.hour }
            .map { TideLevelPoint(id: $0.hour, hour: $0.hour, level: $0.level) }
    }

    private var currentLevel: Double? {
        let pts = points
        guard !pts.isEmpty else { return nil }
        let x = currentX
        for i in 0..<(pts.count - 1) {
            let a = pts[i], b = pts[i+1]
            if Double(a.hour) <= x && x <= Double(b.hour) {
                let span = Double(b.hour - a.hour)
                guard span > 0 else { return a.level }
                let t = (x - Double(a.hour)) / span
                return a.level + (b.level - a.level) * t
            }
        }
        return pts.last?.level
    }

    // Local maxima/minima across the full day, so we can find the *next* event
    // even when the day's single H and L (from TideInfo) are both already past.
    private var turningPoints: [(hour: Int, kind: String)] {
        let pts = points
        guard pts.count >= 3 else { return [] }
        var out: [(hour: Int, kind: String)] = []
        for i in 1..<(pts.count - 1) {
            let prev = pts[i-1].level, curr = pts[i].level, next = pts[i+1].level
            if curr > prev && curr > next { out.append((pts[i].hour, "H")) }
            if curr < prev && curr < next { out.append((pts[i].hour, "L")) }
        }
        return out
    }

    private var trend: String {
        let pts = points
        guard pts.count >= 2 else { return "" }
        let x = currentX
        for i in 0..<(pts.count - 1) {
            let a = pts[i], b = pts[i+1]
            if Double(a.hour) <= x && x <= Double(b.hour) {
                let delta = b.level - a.level
                if delta > 0.05 { return "Rising" }
                if delta < -0.05 { return "Falling" }
                return "Slack"
            }
        }
        return ""
    }

    private var headlineText: String {
        let next = turningPoints.first { Double($0.hour) > currentX }
        guard !trend.isEmpty else { return "—" }
        guard let next else { return trend }
        let hoursUntil = max(0, Int((Double(next.hour) - currentX).rounded()))
        let label = next.kind == "H" ? "high" : "low"
        if hoursUntil == 0 { return "\(trend) · \(label) now" }
        return "\(trend) · \(label) in \(hoursUntil)h"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tide")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text(headlineText)
                        .font(.title3.bold())
                }
                Spacer()
            }

            if points.count >= 2 {
                Chart {
                    ForEach(points) { p in
                        AreaMark(
                            x: .value("Hour", p.hour),
                            y: .value("Level", p.level)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.25), Color.blue.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        LineMark(
                            x: .value("Hour", p.hour),
                            y: .value("Level", p.level)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Color.blue.opacity(0.8))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }

                    if let level = currentLevel {
                        RuleMark(x: .value("Now", currentX))
                            .foregroundStyle(Color.green.opacity(0.35))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                        PointMark(
                            x: .value("Now", currentX),
                            y: .value("Level", level)
                        )
                        .foregroundStyle(Color.green)
                        .symbolSize(120)
                    }
                }
                .chartXScale(domain: 0...23)
                .chartXAxis {
                    AxisMarks(values: [0, 6, 12, 18]) { val in
                        AxisValueLabel {
                            if let h = val.as(Int.self) {
                                Text(String(format: "%02d", h))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 80)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}

struct DetailCard: View {
    let icon: String
    let title: String
    let primary: String
    let secondary: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text(primary)
                    .font(.title3.bold())
                Text(secondary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}
