//
//  ContentView.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 11/24/24.
//

import SwiftUI
import Mixpanel

struct ContentView: View {
    @State private var isLoading = true
    @StateObject private var gameCoordinator = GameCoordinator()
    @StateObject private var dailyCheckManager = DailyCheckManager.shared
    
    var body: some View {
        ZStack {
            Group {
                if isLoading {
                    LoadingView() //custom load screen goes here
                } else {
                    MainMenuView()
                        .environmentObject(gameCoordinator)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isLoading = false
                }
            }
            
            // New Day Overlay - appears on top of everything
            if dailyCheckManager.showNewDayOverlay && !isLoading {
                NewDayOverlay(
                    isVisible: $dailyCheckManager.showNewDayOverlay,
                    onLetsPlay: {
                        dailyCheckManager.dismissNewDayOverlay()
                    }
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            // MIXPANEL ANALYTICS CAPTURE
            Mixpanel.mainInstance().track(event: "App Loading Page View", properties: [
                "app": "Decode! Daily iOS",
                "build_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"],
                "date": Date().formatted(),
                "subscription_tier": SubscriptionManager.shared.currentTier.displayName
            ])
            print("📈 🪵 MIXPANEL DATA LOG EVENT: App Loading Page View")
            print("📈 🪵 date: \(Date().formatted())")
            print("📈 🪵 sub tier: \(SubscriptionManager.shared.currentTier.displayName)")
        }
        // Reset navigation when coordinator says to return to main menu
        .onChange(of: gameCoordinator.shouldReturnToMainMenu) { oldValue, newValue in
            if newValue {
                // This will trigger navigation back to main menu
                // Reset the flag
                gameCoordinator.shouldReturnToMainMenu = false
            }
        }
            }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            LinearGradient.mainmenuViewGradient.ignoresSafeArea()
            
            ZStack {
                //Color.black.ignoresSafeArea()
                Image("TitleLoader-w")
                    .resizable()
                    .scaledToFit()
            }
            .padding(40)
        }
            }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
