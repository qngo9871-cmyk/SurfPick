import SwiftUI

@main
struct SurfPickApp: App {
    @StateObject private var store = StoreKitManager()

    var body: some Scene {
        WindowGroup {
            RankedListView()
                .environmentObject(store)
        }
    }
}
