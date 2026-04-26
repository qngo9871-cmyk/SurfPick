import SwiftUI

struct InfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    section(
                        title: "How Surf Pick picks",
                        body: "We check the nearest 10 surf breaks to your current location, fetch live wave and wind conditions for each, and show the best one first. Tap any spot for full conditions and directions."
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ratings")
                            .font(.title3.bold())
                        ratingRow(
                            color: Color(red: 52/255, green: 199/255, blue: 89/255),
                            title: "Green — go",
                            description: "Clean offshore wind, decent wave height and period. Worth the drive."
                        )
                        ratingRow(
                            color: Color(red: 255/255, green: 149/255, blue: 0/255),
                            title: "Amber — maybe",
                            description: "Borderline. Cross-shore wind, small or short-period swell. Could be okay if you're already there."
                        )
                        ratingRow(
                            color: Color(red: 255/255, green: 59/255, blue: 48/255),
                            title: "Red — sit it out",
                            description: "Onshore wind, flat or messy. Save the drive."
                        )
                    }

                    section(
                        title: "Why period matters more than height",
                        body: "A 1.2 m wave at 12 seconds period is far better than 2 m at 6 seconds. Period reflects how organised the swell is — longer-period waves break with more power and shape."
                    )

                    section(
                        title: "Data source",
                        body: "Wave height, period, direction, and wind data come from Open-Meteo (open-meteo.com/marine), a free and open marine weather API. Forecasts are model-based estimates — always trust your eyes when you arrive at the spot."
                    )

                    section(
                        title: "Spot accuracy",
                        body: "Surf break locations are continually being improved. If a spot is in the wrong place, tap it from the main list, then \"Report wrong location\" at the bottom of the detail screen. Your reports go to the developer and feed into the next dataset update."
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Surf Pick \(appVersion)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("Conditions data © Open-Meteo. Surf Pick is built by Quyen Ngo.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func section(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.title3.bold())
            Text(body)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func ratingRow(color: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Circle()
                .fill(color)
                .frame(width: 18, height: 18)
                .padding(.top, 4)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.semibold))
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var appVersion: String {
        let dict = Bundle.main.infoDictionary ?? [:]
        let version = dict["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = dict["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }
}

#Preview {
    InfoView()
}
