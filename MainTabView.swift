//
//  MainTabView.swift
//  Decode! Daily iOS
//
//  Created by Assistant on 9/15/25.
//

import SwiftUI
import Mixpanel

struct MainTabView: View {
    @Binding var currentPage: Int
    @Binding var navigateToGame: String?
    @Binding var navigateToArchivedGame: (gameId: String, date: Date)?
    @Binding var showArchiveUpsell: Bool
    
    @EnvironmentObject var scoreManager: GameScoreManager
    @EnvironmentObject var gameCoordinator: GameCoordinator
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    // Updated to use UserDefaults for persistence
    @State private var selectedArchiveGame: String = UserDefaults.standard.string(forKey: "selectedArchiveGame") ?? "decode"
    @State private var hasUserSwiped: Bool = UserDefaults.standard.bool(forKey: "hasSeenSwipeInstruction")
    
    var body: some View {
        TabView(selection: $currentPage) {
            
            MainMenuPageView(
                navigateToGame: $navigateToGame,
                hasUserSwiped: hasUserSwiped
            )
            .tag(0)
            
            ArchivePageView(
                selectedArchiveGame: $selectedArchiveGame,
                navigateToArchivedGame: $navigateToArchivedGame,
                showArchiveUpsell: $showArchiveUpsell
            )
            .tag(1)
            
            AccountPageView()
                .tag(2)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .onChange(of: currentPage) { oldValue, newValue in
            handlePageChange(newValue)
        }
        // Save the selected archive game whenever it changes
        .onChange(of: selectedArchiveGame) { oldValue, newValue in
            UserDefaults.standard.set(newValue, forKey: "selectedArchiveGame")
        }
    }
    
    private func handlePageChange(_ newValue: Int) {
        if currentPage != 0 && !hasUserSwiped {
            hasUserSwiped = true
            UserDefaults.standard.set(true, forKey: "hasSeenSwipeInstruction")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if currentPage == newValue {
                trackPageView(for: newValue)
            }
        }
    }
    
    private func trackPageView(for page: Int) {
        let eventName: String
        switch page {
        case 0:
            eventName = "Main Menu Page View"
        case 1:
            eventName = "Archives Main Page View"
        case 2:
            eventName = "Stats Main Page View"
        default:
            return
        }
        
        Mixpanel.mainInstance().track(event: eventName, properties: [
            "app": "Decode! Daily iOS",
            "build_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"],
            "date": Date().formatted(),
            "subscription_tier": SubscriptionManager.shared.currentTier.displayName
        ])
        
        print("📈 🪵 MIXPANEL DATA LOG EVENT: \(eventName)")
        print("📈 🪵 date: \(Date().formatted())")
        print("📈 🪵 sub tier: \(SubscriptionManager.shared.currentTier.displayName)")
    }
}
