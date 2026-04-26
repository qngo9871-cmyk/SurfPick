import SwiftUI
import UIKit
import CoreLocation
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
                            DetailCard(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Tide",
                                primary: tideSummary(tide),
                                secondary: "Today's high & low"
                            )
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
        let coord = `break`.nearby.spot.coordinate
        let name = `break`.nearby.spot.name
        let dict = Bundle.main.infoDictionary ?? [:]
        let version = dict["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = dict["CFBundleVersion"] as? String ?? "1"

        let subject = "Surf Pick — Wrong location: \(name)"
        let body = """
        Spot: \(name)
        Claimed coords: \(coord.latitude), \(coord.longitude)

        Correct coords (paste from Google/Apple Maps long-press):


        Notes (optional):


        ---
        Surf Pick v\(version) (\(build))
        """

        let allowed = CharacterSet.urlQueryAllowed
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: allowed) ?? subject
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: allowed) ?? body
        let urlString = "mailto:qngo9871@gmail.com?subject=\(encodedSubject)&body=\(encodedBody)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    private func tideSummary(_ tide: TideInfo) -> String {
        var parts: [String] = []
        if let highTime = tide.nextHighTime {
            parts.append("H \(highTime)")
        }
        if let lowTime = tide.nextLowTime {
            parts.append("L \(lowTime)")
        }
        return parts.isEmpty ? "—" : parts.joined(separator: " · ")
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
