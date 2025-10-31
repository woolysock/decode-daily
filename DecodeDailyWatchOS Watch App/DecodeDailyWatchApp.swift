import SwiftUI

@main
struct DecodeDailyWatchApp: App {
    @StateObject private var gameCoordinator = GameCoordinator()
    @StateObject private var gameScoreManager = GameScoreManager.shared

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(gameCoordinator)
                .environmentObject(gameScoreManager)
        }
    }
}
