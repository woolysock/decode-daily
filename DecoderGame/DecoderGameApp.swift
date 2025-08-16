//
//  DecoderGameApp.swift
//  Decode! Daily
//
//  Created by Megan Donahue on 11/24/24.
//

import SwiftUI
import SwiftData

@main
struct DecoderGameApp: App {
    // Remove the @StateObject and use the shared instance instead
    // @StateObject var scoreManager = GameScoreManager()
  
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(GameScoreManager.shared)
        }
        .modelContainer(sharedModelContainer)
    }
}
