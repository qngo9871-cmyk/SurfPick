import Foundation
import Combine
import StoreKit

@MainActor
final class StoreKitManager: ObservableObject {
    static let proProductID = "com.quyenngo.surfpick.pro"

    @Published private(set) var isPro: Bool = false
    @Published private(set) var product: Product?
    @Published private(set) var purchaseError: String?

    var displayPrice: String { product?.displayPrice ?? "$4.99" }

    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(verification: result)
            }
        }
        Task { await refreshState() }
    }

    deinit {
        transactionListener?.cancel()
    }

    func refreshState() async {
        async let productLoad: Void = loadProduct()
        async let entitlement: Bool = checkEntitlement()
        let (_, hasPro) = await (productLoad, entitlement)
        if isPro != hasPro { isPro = hasPro }
    }

    private func checkEntitlement() async -> Bool {
        for await verification in Transaction.currentEntitlements {
            if case .verified(let tx) = verification,
               tx.productID == Self.proProductID,
               tx.revocationDate == nil {
                return true
            }
        }
        return false
    }

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.proProductID])
            product = products.first
        } catch {
            // Silent — UI shows fallback price; we'll retry when user taps Unlock.
        }
    }

    func purchase() async {
        if product == nil { await loadProduct() }
        guard let product else {
            purchaseError = "Couldn't load Pro product. Check your connection."
            return
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let tx) = verification {
                    isPro = true
                    await tx.finish()
                    purchaseError = nil
                } else {
                    purchaseError = "Purchase couldn't be verified."
                }
            case .userCancelled:
                break
            case .pending:
                purchaseError = "Purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            purchaseError = "Purchase failed. \(error.localizedDescription)"
        }
    }

    func restore() async -> RestoreResult {
        do {
            try await AppStore.sync()
            let wasPro = isPro
            await refreshState()
            if isPro { return wasPro ? .alreadyActive : .restored }
            return .nothingToRestore
        } catch {
            purchaseError = "Restore failed. \(error.localizedDescription)"
            return .failed
        }
    }

    private func handle(verification: VerificationResult<Transaction>) async {
        if case .verified(let tx) = verification,
           tx.productID == Self.proProductID,
           tx.revocationDate == nil {
            isPro = true
            await tx.finish()
        }
    }
}

enum RestoreResult {
    case restored
    case alreadyActive
    case nothingToRestore
    case failed
}
