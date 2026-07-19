import Foundation
import RevenueCat

/// RevenueCat wiring — **OBSERVER MODE only**.
///
/// `StoreKitManager` keeps doing all purchasing, restoring and entitlement
/// checks exactly as App Review approved. RevenueCat is configured with
/// `purchasesAreCompletedBy: .myApp` so it merely OBSERVES the StoreKit 2
/// transaction `StoreKitManager` already finishes — it never touches the
/// purchase flow, never gates entitlements, and never shows UI.
///
/// Its only job is attribution: segmenting installs/purchases by Apple Search
/// Ads campaign / ad group. Attribution resolves to campaign + ad-group level,
/// not per individual keyword — expected with the free AdServices stack.
enum RevenueCatService {

    private static let apiKey = "appl_CGzAbheOwANGfbiDrxvguxtIlin"

    /// Configure RevenueCat. Call once, as early as possible, from
    /// `SurfPickApp.init()`.
    static func configure() {
        Purchases.logLevel = .info

        Purchases.configure(
            with: Configuration.Builder(withAPIKey: apiKey)
                .with(purchasesAreCompletedBy: .myApp, storeKitVersion: .storeKit2)
                .build()
        )

        // Apple Search Ads attribution. iOS 14.3+, no ATT prompt and no IDFA
        // for standard attribution. Links tap → install → purchase to the ASA
        // campaign / ad group in the RevenueCat dashboard.
        Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()

        // Backfill the existing StoreKit transaction so paid unlockers show up.
        // Idempotent and cheap; fine to run on each launch.
        Task { _ = try? await Purchases.shared.syncPurchases() }
    }
}
