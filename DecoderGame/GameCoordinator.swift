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
    
    // Game managers with date management capabilities
    @Published var dailyEquationManager = DailyEquationManager.shared
    @Published var dailyWordsetManager = DailyWordsetManager.shared
    @Published var dailyCodeSetManager = DailyCodeSetManager.shared
    
    private let dailyCheckManager = DailyCheckManager.shared
    
    // Date management for archive cache invalidation
    @Published private var lastKnownDate = Calendar.current.startOfDay(for: Date())
    private var dateCache: [String: [Date]] = [:]
    private var cacheTimestamp: Date?
    
    init() {
        dailyCheckManager.gameDelegate = self
        startDateMonitoring()
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
    
    // MARK: - Date Management
    
    private func startDateMonitoring() {
        // Monitor for day changes every minute
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkForDayChange()
        }
    }
    
    private func checkForDayChange() {
        let currentDate = Calendar.current.startOfDay(for: Date())
        if currentDate != lastKnownDate {
            print("GameCoordinator: Day change detected from \(lastKnownDate) to \(currentDate)")
            lastKnownDate = currentDate
            invalidateArchiveCache()
        }
    }
    
    private func invalidateArchiveCache() {
        print("GameCoordinator: Invalidating archive date cache")
        dateCache.removeAll()
        cacheTimestamp = nil
    }
    
    // MARK: - Archive Date Management
    
    func getAvailableDates(for gameId: String) -> [Date] {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Check if cache is valid (same day and exists)
        if let timestamp = cacheTimestamp,
           Calendar.current.isDate(timestamp, inSameDayAs: today),
           let cachedDates = dateCache[gameId] {
            return cachedDates
        }
        
        // Load fresh dates
        let dates = loadDatesForGame(gameId)
        
        // Cache the results
        dateCache[gameId] = dates
        cacheTimestamp = today
        
        return dates
    }
    
    private func loadDatesForGame(_ gameId: String) -> [Date] {
        print("GameCoordinator: Loading fresh dates for \(gameId)")
        let today = Calendar.current.startOfDay(for: Date())
        
        var rawDates: [Date] = []
        
        switch gameId {
        case "decode":
            rawDates = dailyCodeSetManager.getAvailableDates()
        case "flashdance":
            rawDates = dailyEquationManager.getAvailableDates()
        case "anagrams":
            rawDates = dailyWordsetManager.getAvailableDates()
        default:
            print("GameCoordinator: Unknown gameId: \(gameId)")
            return []
        }
        
        // Convert UTC dates to local timezone if needed
        let localCalendar = Calendar.current
        let localDates = rawDates.compactMap { utcDate -> Date? in
            var utcCalendar = Calendar(identifier: .gregorian)
            utcCalendar.timeZone = TimeZone(abbreviation: "UTC")!
            
            let components = utcCalendar.dateComponents([.year, .month, .day], from: utcDate)
            return localCalendar.date(from: components)
        }
        
        // Filter out today and future dates, then sort (most recent first)
        let filteredDates = localDates.filter { $0 < today }.sorted(by: >)
        
        print("GameCoordinator: Loaded \(filteredDates.count) dates for \(gameId)")
        if let mostRecent = filteredDates.first {
            print("GameCoordinator: Most recent date: \(mostRecent)")
        }
        
        return filteredDates
    }
    
    // MARK: - DailyCheckGameDelegate
    
    func newDayDetected() {
        print("GameCoordinator: New day detected!")
        
        // Invalidate archive cache immediately
        invalidateArchiveCache()
        
        // Handle different game states - END all games, don't pause
        if let activeGame = currentlyActiveGame {
            print("GameCoordinator: Force ending active game: \(activeGame)")
            
            switch activeGame {
            case "anagrams":
                // Handled by AnagramsGameView
                break
            case "flashdance":
                // Handled by FlashdanceGameView
                break
            case "decode":
                // Handled by DecodeGameView
                break
            case "numbers":
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
