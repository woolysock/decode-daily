//
//  MainMenuView.swift
//  Decode! Daily iOS
//
//  Refactored on 9/15/25.
//

import SwiftUI
import Mixpanel

struct MainMenuView: View {
    // Core navigation state
    @State private var currentPage: Int
    @State private var navigateToGame: String? = nil
    @State private var navigateToArchivedGame: (gameId: String, date: Date)? = nil
    @State private var showArchiveUpsell = false
    
    // Environment objects
    @EnvironmentObject var scoreManager: GameScoreManager
    @EnvironmentObject var gameCoordinator: GameCoordinator
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var navigateToLeaderboard: String? = nil
    
    init(initialPage: Int = 0, selectedGame: String = "decode") {
        _currentPage = State(initialValue: initialPage)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer().frame(height: 5)
                    HeaderSectionView()
                    MainTabView(
                        currentPage: $currentPage,
                        navigateToGame: $navigateToGame,
                        navigateToArchivedGame: $navigateToArchivedGame,
                        showArchiveUpsell: $showArchiveUpsell
                    )
                    BottomNavigationBar(currentPage: currentPage)
                    Spacer().frame(height: 20)
                }
                .zIndex(0)
                .background(.clear)
                .ignoresSafeArea(.all, edges: .bottom)
                
                if showArchiveUpsell {
                    ArchiveUpsellOverlay(isPresented: $showArchiveUpsell)
                        .environmentObject(subscriptionManager)
                        .zIndex(1)
                }
            }
            .navigationBarBackButtonHidden(true)
            
            .navigationDestination(isPresented: gameNavigationBinding) {
                if let gameId = navigateToGame {
                    destinationView(for: gameId)
                }
            }
            .navigationDestination(isPresented: archivedGameNavigationBinding) {
                if let archivedGame = navigateToArchivedGame {
                    archivedGameDestination(for: archivedGame.gameId, date: archivedGame.date)
                }
            }
            .navigationDestination(isPresented: leaderboardNavigationBinding) {
                if let gameId = navigateToLeaderboard {
                    MultiGameLeaderboardView(selectedGameID: gameId)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToArchive"))) { notification in
                handleArchiveNavigation(notification)
            }
            .environmentObject(subscriptionManager)
        }
    }
    
    // MARK: - Navigation Bindings
    
    private var leaderboardNavigationBinding: Binding<Bool> {
        Binding<Bool>(
            get: { navigateToLeaderboard != nil },
            set: { if !$0 { navigateToLeaderboard = nil } }
        )
    }
    
    private var gameNavigationBinding: Binding<Bool> {
        Binding<Bool>(
            get: { navigateToGame != nil },
            set: { if !$0 { navigateToGame = nil } }
        )
    }
    
    private var archivedGameNavigationBinding: Binding<Bool> {
        Binding<Bool>(
            get: { navigateToArchivedGame != nil },
            set: { if !$0 { navigateToArchivedGame = nil } }
        )
    }
    
    // MARK: - Navigation Helpers
    private func handleArchiveNavigation(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let _ = userInfo["gameId"] as? String {
            currentPage = 1
        }
    }
    
    @ViewBuilder
    private func destinationView(for gameId: String) -> some View {
        switch gameId {
        case "decode":
            DecodeGameView()
                .environmentObject(scoreManager)
                .onAppear { gameCoordinator.setActiveGame("decode") }
                .onDisappear { gameCoordinator.clearActiveGame() }
        case "flashdance":
            FlashdanceGameView()
                .environmentObject(scoreManager)
                .onAppear { gameCoordinator.setActiveGame("flashdance") }
                .onDisappear { gameCoordinator.clearActiveGame() }
            
        case "anagrams":
            AnagramsGameView()
                .environmentObject(scoreManager)
                .onAppear { gameCoordinator.setActiveGame("anagrams") }
                .onDisappear { gameCoordinator.clearActiveGame() }
            
        case "numbers":
            NumbersGameView()
                .environmentObject(scoreManager)
                .onAppear { gameCoordinator.setActiveGame("numbers") }
                .onDisappear { gameCoordinator.clearActiveGame() }
            
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func archivedGameDestination(for gameId: String, date: Date) -> some View {
        switch gameId {
        case "flashdance":
            FlashdanceGameView(targetDate: date)
                .environmentObject(scoreManager)
                .onAppear { gameCoordinator.setActiveGame("flashdance") }
                .onDisappear { gameCoordinator.clearActiveGame() }
        case "anagrams":
            AnagramsGameView(targetDate: date)
                .environmentObject(scoreManager)
                .onAppear { gameCoordinator.setActiveGame("anagrams") }
                .onDisappear { gameCoordinator.clearActiveGame() }
        case "decode":
            DecodeGameView(targetDate: date)
                .environmentObject(scoreManager)
                .id("decode-\(date.timeIntervalSince1970)")
                .onAppear { gameCoordinator.setActiveGame("decode") }
                .onDisappear { gameCoordinator.clearActiveGame() }
        default:
            EmptyView()
        }
    }
}

// MARK: - Helper Functions
// This calculateTilt function needs to be accessible to all components that use it
func calculateTilt(dragValue: DragGesture.Value, buttonWidth: CGFloat, buttonHeight: CGFloat) -> (x: Double, y: Double) {
    let maxTilt: Double = 10
    let normalizedX = Double(dragValue.location.x / buttonWidth - 0.5) * 2
    let normalizedY = Double(dragValue.location.y / buttonHeight - 0.5) * 2
    return (x: normalizedY * maxTilt, y: -normalizedX * maxTilt)
}

