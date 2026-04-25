import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var preferredProvider: MapsHandoff.Provider = MapsHandoff.preferredProvider

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Default maps app", selection: $preferredProvider) {
                        Text("Google Maps").tag(MapsHandoff.Provider.google)
                        Text("Apple Maps").tag(MapsHandoff.Provider.apple)
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Directions")
                } footer: {
                    Text("Used when you tap \"Get Directions\". You can also pick either app from the break detail screen.")
                }

                Section {
                    Link(destination: URL(string: "https://github.com/quyenngo")!) {
                        Label("Surf Pick on the web", systemImage: "globe")
                    }
                    Link(destination: URL(string: "mailto:hello@panamindpress.com?subject=Surf%20Pick%20feedback")!) {
                        Label("Send feedback", systemImage: "envelope")
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("Surf Pick — where to surf right now.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: preferredProvider) { _, new in
                MapsHandoff.preferredProvider = new
            }
        }
    }
}

#Preview {
    SettingsView()
}
