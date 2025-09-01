//
//  GameCoordinator.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue
//

import SwiftUI

class GameCoordinator: ObservableObject, DailyCheckGameDelegate {
    @Published var currentlyActiveGame: String? = nil
    @Published var shouldReturnToMainMenu = false
    
    private let dailyCheckManager = DailyCheckManager.shared
    @Published var dailyEquationManager = DailyEquationManager.shared
    @Published var dailyWordsetManager = DailyWordsetManager.shared
    
    init() {
        dailyCheckManager.gameDelegate = self
    }
    
    // MARK: - Game State Management
    
    func setActiveGame(_ gameID: String) {
        currentlyActiveGame = gameID
        print("GameCoordinator: Active game set to \(gameID)")
    }
    
    func clearActiveGame() {
        currentlyActiveGame = nil
        print("GameCoordinator: Active game cleared")
    }
    
    // MARK: - DailyCheckGameDelegate
    
    func newDayDetected() {
        print("GameCoordinator: New day detected!")
        
        // Handle different game states - END all games, don't pause
        if let activeGame = currentlyActiveGame {
            print("GameCoordinator: Force ending active game: \(activeGame)")
            
            switch activeGame {
            case "anagrams":
                // Handled by AnagramsGameView
                break
            case "flashdance":
                // Handled by FlashdanceGameView when it observes the overlay
                break
            case "decode", "numbers":
                // For future implementation when these games have daily features
                print("GameCoordinator: \(activeGame) doesn't have daily features yet")
                break
            default:
                break
            }
        }
        
        // The overlay will be shown by the main app structure
    }
    
    func newDayOverlayDismissed() {
        print("GameCoordinator: New day overlay dismissed")
        
        // Return to main menu
        shouldReturnToMainMenu = true
        clearActiveGame()
    }
    
}
