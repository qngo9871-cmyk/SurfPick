import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var store: StoreKitManager
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var isRestoring = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "figure.surfing")
                        .font(.system(size: 56))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.cyan, Color.blue],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .padding(.top, 8)

                    VStack(spacing: 8) {
                        Text("See all 10 nearest breaks")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                        Text("Stop guessing — see every break within reach, ranked by quality.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 18) {
                        FeatureRow(
                            icon: "list.number",
                            title: "All 10 nearest spots",
                            subtitle: "Free shows the top 3 — Pro unlocks the rest."
                        )
                        FeatureRow(
                            icon: "square.fill.text.grid.1x2",
                            title: "Home-screen widget",
                            subtitle: "Today's pick at a glance, no app launch."
                        )
                        FeatureRow(
                            icon: "car.fill",
                            title: "Auto-CarPlay widget",
                            subtitle: "On iOS 26, your widget appears on your dashboard."
                        )
                        FeatureRow(
                            icon: "infinity",
                            title: "One-time payment",
                            subtitle: "No subscription. Pay once, yours forever."
                        )
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 12)

                    Button {
                        Task { await runPurchase() }
                    } label: {
                        Group {
                            if isPurchasing {
                                ProgressView().tint(.white)
                            } else {
                                Text("Unlock for \(displayPrice)")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isPurchasing || isRestoring)
                    .padding(.horizontal)

                    Button {
                        Task { await runRestore() }
                    } label: {
                        if isRestoring {
                            ProgressView()
                        } else {
                            Text("Restore Purchases")
                                .font(.subheadline)
                        }
                    }
                    .foregroundStyle(.secondary)
                    .disabled(isPurchasing || isRestoring)

                    if let err = store.purchaseError {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Text("One-time payment. No subscription.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.bottom, 24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .imageScale(.large)
                    }
                }
            }
            .onChange(of: store.isPro) { _, newValue in
                if newValue { dismiss() }
            }
        }
    }

    private var displayPrice: String {
        store.product?.displayPrice ?? "$4.99"
    }

    private func runPurchase() async {
        isPurchasing = true
        await store.purchase()
        isPurchasing = false
    }

    private func runRestore() async {
        isRestoring = true
        _ = await store.restore()
        isRestoring = false
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.semibold))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(StoreKitManager())
}
