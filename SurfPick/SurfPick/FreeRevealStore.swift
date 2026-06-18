import Foundation
import StoreKit

/// Tracks the free "reveal the #1 pick" allowance. New users get a few free looks
/// at the best break before it's gated behind the one-time Pro unlock. Persisted
/// in UserDefaults; reset for screenshots/testing via the launch arg
/// `-surfpick.freeRevealsUsed <n>`.
enum FreeRevealStore {
    static let limit = 3
    private static let usedKey = "surfpick.freeRevealsUsed"
    private static let reviewAskedKey = "surfpick.reviewAsked"

    static var used: Int { UserDefaults.standard.integer(forKey: usedKey) }
    static var hasFreeRevealsLeft: Bool { used < limit }

    static func consume() {
        let n = used
        if n < limit { UserDefaults.standard.set(n + 1, forKey: usedKey) }
    }

    static var reviewAsked: Bool { UserDefaults.standard.bool(forKey: reviewAskedKey) }
    static func markReviewAsked() { UserDefaults.standard.set(true, forKey: reviewAskedKey) }
}

/// Shared Pro-entitlement check usable from both the app and the App Intent
/// (the intent has no access to the StoreKitManager environment object).
enum ProAccess {
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
