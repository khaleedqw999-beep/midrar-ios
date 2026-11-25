import SwiftUI

@main
struct MidrarApp: App {
    @StateObject private var store = MidrarStore()

    var body: some Scene {
        WindowGroup {
            MainTabContainerView()
                .environmentObject(store)
                .environment(\.layoutDirection, .rightToLeft)
                .preferredColorScheme(store.preferredColorScheme)
                .onAppear {
                    store.refreshLeaderboardAndConfig()
                    if store.state.hasCompletedOnboarding {
                        NotificationService.requestAndSchedule(state: store.state)
                    }
                }
        }
    }
}
