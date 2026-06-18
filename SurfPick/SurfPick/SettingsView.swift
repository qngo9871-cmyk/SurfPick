import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: StoreKitManager
    @State private var preferredProvider: MapsHandoff.Provider = MapsHandoff.preferredProvider
    @State private var showPaywall = false
    @State private var isRestoring = false
    @State private var restoreMessage: String?
    #if DEBUG
    @State private var aboutTapCount: Int = 0
    @State private var devUnlockMessage: String?
    #endif

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if store.isPro {
                        HStack {
                            Label("Pro Active", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                            Spacer()
                            Text("Thanks!")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Label("Upgrade to Pro", systemImage: "lock.open.fill")
                                Spacer()
                                Text(store.displayPrice)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Button {
                        Task { await runRestore() }
                    } label: {
                        HStack {
                            Label("Restore Purchases", systemImage: "arrow.clockwise")
                            Spacer()
                            if isRestoring {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isRestoring)
                } header: {
                    Text("Pro")
                } footer: {
                    if let restoreMessage {
                        Text(restoreMessage)
                    } else {
                        Text("Pro reveals the #1 best spot, unlocks all 10 nearest spots and the home-screen widget. One-time payment, no subscription.")
                    }
                }

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
                    Link(destination: URL(string: "mailto:qngo9871@gmail.com?subject=Surf%20Pick%20feedback")!) {
                        Label("Send feedback", systemImage: "envelope")
                    }
                } header: {
                    Text("About")
                } footer: {
                    #if DEBUG
                    // Dev-only: tap the footer 7x to toggle a Pro unlock for testing.
                    // Compiled out of Release builds so customers never see or trigger it.
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Surf Pick — where to surf right now.")
                        if let devUnlockMessage {
                            Text(devUnlockMessage)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture { handleAboutTap() }
                    #else
                    Text("Surf Pick — where to surf right now.")
                    #endif
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
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(store)
            }
        }
    }

    #if DEBUG
    private func handleAboutTap() {
        aboutTapCount += 1
        if aboutTapCount >= 7 {
            let on = store.toggleDevUnlock()
            devUnlockMessage = on ? "Dev unlock ON — Pro features active" : "Dev unlock OFF"
            aboutTapCount = 0
        } else if aboutTapCount >= 3 {
            devUnlockMessage = "\(7 - aboutTapCount) more taps…"
        }
    }
    #endif

    private func runRestore() async {
        isRestoring = true
        restoreMessage = nil
        let result = await store.restore()
        isRestoring = false
        switch result {
        case .restored:        restoreMessage = "Pro restored. Thanks!"
        case .alreadyActive:   restoreMessage = "Pro is already active."
        case .nothingToRestore: restoreMessage = "No previous purchase found on this Apple ID."
        case .failed:          restoreMessage = store.purchaseError ?? "Restore failed. Try again."
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(StoreKitManager())
}
