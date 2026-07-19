import SwiftUI

@main
struct SurfPickApp: App {
    @StateObject private var store = StoreKitManager()

    init() {
        RevenueCatService.configure()
    }

    var body: some Scene {
        WindowGroup {
            RankedListView()
                .environmentObject(store)
        }
    }
}
