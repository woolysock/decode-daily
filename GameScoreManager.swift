//
//  GameScoreManager.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/14/25.
//

import Foundation
import SwiftUI
import Mixpanel

// MARK: - Game-specific additional properties structures
struct FlashdanceAdditionalProperties: Codable {
    let gameDuration: Int
    let correctAnswers: Int
    let incorrectAnswers: Int
    let longestStreak: Int
    let gameDate: Date?
    
}

struct DecodeAdditionalProperties: Codable {
    let gameDuration: TimeInterval // Duration of the game
    let turnsToSolve: Int         // Number of turns taken to solve
    let codeLength: Int           // Number of squares in the code
}

struct AnagramsAdditionalProperties: Codable {
    let gameDuration: TimeInterval
    let longestWord: Int
    let totalWordsInSet: Int
    let wordsCompleted: Int        // NEW
    let wordsetId: String         // NEW
    let completedWordLengths: [Int]  // NEW
    let difficultyScore: Double      // NEW
    let skippedWords: Int
}

// MARK: - Enhanced GameScore with additional properties
struct GameScore: Codable, Identifiable, Equatable {
    let id: UUID
    let gameId: String           // "flashdance", "decode", "anagrams"
    let date: Date               // when the game was played
    let archiveDate: Date?       // the “target” or archived date (e.g., targetDate in Flashdance)
    let attempts: Int
    let timeElapsed: TimeInterval
    let won: Bool
    let finalScore: Int
    let additionalPropertiesData: Data?

    // MARK: - Initializers
    init(gameId: String,
         date: Date,
         archiveDate: Date? = nil,
         attempts: Int,
         timeElapsed: TimeInterval,
         won: Bool,
         finalScore: Int)
    {
        self.id = UUID()
        self.gameId = gameId
        self.date = date
        self.archiveDate = archiveDate
        self.attempts = attempts
        self.timeElapsed = timeElapsed
        self.won = won
        self.finalScore = finalScore
        self.additionalPropertiesData = nil
    }

    init<T: Codable>(gameId: String,
                     date: Date,
                     archiveDate: Date? = nil,
                     attempts: Int,
                     timeElapsed: TimeInterval,
                     won: Bool,
                     finalScore: Int,
                     additionalProperties: T?)
    {
        self.id = UUID()
        self.gameId = gameId
        self.date = date
        self.archiveDate = archiveDate
        self.attempts = attempts
        self.timeElapsed = timeElapsed
        self.won = won
        self.finalScore = finalScore

        if let properties = additionalProperties {
            self.additionalPropertiesData = try? JSONEncoder().encode(properties)
        } else {
            self.additionalPropertiesData = nil
        }
    }
    

    // MARK: - Additional Properties Accessors
    
    /// Get Flashdance-specific additional properties
    var flashdanceProperties: FlashdanceAdditionalProperties? {
        guard gameId == "flashdance", let data = additionalPropertiesData else { return nil }
        return try? JSONDecoder().decode(FlashdanceAdditionalProperties.self, from: data)
    }
    
    /// Get Decode-specific additional properties
    var decodeProperties: DecodeAdditionalProperties? {
        guard gameId == "decode", let data = additionalPropertiesData else { return nil }
        return try? JSONDecoder().decode(DecodeAdditionalProperties.self, from: data)
    }
    
    /// Get Anagrams-specific additional properties
    var anagramsProperties: AnagramsAdditionalProperties? {
        guard gameId == "anagrams", let data = additionalPropertiesData else { return nil }
        return try? JSONDecoder().decode(AnagramsAdditionalProperties.self, from: data)
    }

    // MARK: - Display helpers
    var formattedTime: String {
        let minutes = Int(timeElapsed) / 60
        let seconds = Int(timeElapsed) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Enhanced Display Helpers for Additional Properties
    
    /// Get formatted additional info string for display
    var additionalInfoString: String? {
        switch gameId {
        case "flashdance":
            guard let props = flashdanceProperties else { return nil }
            return "Correct: \(props.correctAnswers) • Wrong: \(props.incorrectAnswers)\nBest Streak: \(props.longestStreak)"
            
        case "decode":
            guard let props = decodeProperties else { return nil }
            return "Turns: \(props.turnsToSolve)/7\nCode Length: \(props.codeLength) • Time: \(formatDuration(props.gameDuration))"
            
        case "anagrams":
            guard let props = anagramsProperties else { return nil }
            return "Longest word: \(props.longestWord)\n Total possible words: \(props.totalWordsInSet)"
        default:
            return nil
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

class GameScoreManager: ObservableObject {

    @Published var allScores: [GameScore] = []
    static let shared = GameScoreManager()
    private let userDefaults = UserDefaults.standard
    private let scoresKey = "SavedGameScores"

    // MODIFIED: Made init private to enforce singleton pattern
    private init() {
        loadScores()
    }

    // MARK: - Enhanced Save Methods
    
    // Save a new score - FIXED to ensure main thread updates
    func saveScore(_ score: GameScore) {
        //print("🔄 About to save score: \(score.finalScore) for \(score.gameId)")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.allScores.append(score)
            self.saveToUserDefaults()

            
            
//            print("saveScore(): score.date = \(score.date)")
//            print("saveScore(): score.archiveDate = \(String(describing: score.archiveDate))")
//            print("saveScore(): Date() = \(Date())")
//            print("saveScore(): Date() formatted = \(DateFormatter.scorePlayedDisplayFormatter.string(from: Date()))")
//            
            //let markDate = score.archiveDate ?? score.date
            let markDate = score.archiveDate ?? score.date
            
            //print("saveScore(): markDate = \(markDate)")
            
            self.markGameCompleted(gameId: score.gameId, date: markDate)

            print("✅ Score saved on main thread! score.date = \(score.date)")
            print("✅ Scores for \(score.gameId): \(self.allScores.filter { $0.gameId == score.gameId }.count)")

            
            // MIXPANEL ANALYTICS CAPTURE
            Mixpanel.mainInstance().track(event: "Game Score Saved", properties: [
                "app": "Decode! Daily iOS",
                "build_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"],
                "date": Date().formatted(),
                "subscription_tier": SubscriptionManager.shared.currentTier.displayName,
                "game": score.gameId,
                "game_archive_date": markDate,
                "final_score": score.finalScore
            ])
            print("📈 🪵 MIXPANEL DATA LOG EVENT: Game Score Saved")
            print("📈 🪵 date: \(Date().formatted())")
            print("📈 🪵 sub tier: \(SubscriptionManager.shared.currentTier.displayName)")
            print("📈 🪵 game: \(score.gameId)")
            print("📈 🪵 game_archive_date: \(markDate)")
            print("📈 🪵 final_score: \(score.finalScore)")
            
            self.objectWillChange.send()
        }
    }

    func getScoresFromLastWeek() -> [GameScore] {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        return allScores.filter { score in
            score.date >= oneWeekAgo
        }
    }
    
    // MARK: - Convenience Save Methods for Specific Games
    

    /// Save a Flashdance score with additional properties
    func saveFlashdanceScore(
        date: Date,
        archiveDate: Date? = nil,
        attempts: Int,
        timeElapsed: TimeInterval,
        finalScore: Int,
        gameDuration: Int,
        correctAnswers: Int,
        incorrectAnswers: Int,
        longestStreak: Int,
        gameDate: Date  // Add this parameter
    ) {
        //print("Calling saveFlashdanceScore()")
        let additionalProps = FlashdanceAdditionalProperties(
            gameDuration: gameDuration,
            correctAnswers: correctAnswers,
            incorrectAnswers: incorrectAnswers,
            longestStreak: longestStreak,
            gameDate: gameDate  // Include the archive date
        )
        
        let score = GameScore(
            gameId: "flashdance",
            date: date,  // This is when the game was played
            archiveDate: archiveDate,
            attempts: attempts,
            timeElapsed: timeElapsed,
            won: true,
            finalScore: finalScore,
            additionalProperties: additionalProps
        )
        
        saveScore(score)
    }
    
    /// Save a Decode score with additional properties
    func saveDecodeScore(
        date: Date = Date(),
        archiveDate: Date? = nil,
        attempts: Int,
        timeElapsed: TimeInterval,
        won: Bool,
        finalScore: Int,
        turnsToSolve: Int,
        codeLength: Int
    ) {
        //print("Calling saveDecodeScore()")
        let additionalProps = DecodeAdditionalProperties(
            gameDuration: timeElapsed,
            turnsToSolve: turnsToSolve,
            codeLength: codeLength
        )
        
        let score = GameScore(
            gameId: "decode",
            date: date,
            archiveDate: archiveDate,
            attempts: attempts,
            timeElapsed: timeElapsed,
            won: won,
            finalScore: finalScore,
            additionalProperties: additionalProps
        )
        
        saveScore(score)
    }

    
    // Get scores for a specific game
    func getScores(for gameId: String) -> [GameScore] {
        let filteredScores = allScores
            .filter { $0.gameId == gameId }
            .sorted { $0.finalScore > $1.finalScore }
        
        //print("📊 getScores for '\(gameId)': found \(filteredScores.count) scores")
        return filteredScores
    }

    // Get top scores across all games
    func getTopScores(limit: Int = 10) -> [GameScore] {
        allScores
            .sorted { $0.finalScore > $1.finalScore }
            .prefix(limit)
            .map { $0 }
    }

    // Get recent scores
    func getRecentScores(limit: Int = 5) -> [GameScore] {
        allScores
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .map { $0 }
    }

    // Example scoring method (customize per game)
    static func calculateDecodeScore(attempts: Int, timeElapsed: TimeInterval, won: Bool, maxAttempts: Int = 7) -> Int {
        guard won else { return 0 }
        
        let baseScore = 100
        
        // Heavy penalty for more attempts (this should be the primary factor)
        let attemptPenalty = (attempts - 1) * 15  // Increased from 100
        
        // Time penalty - but cap it so time doesn't dominate the score
        // Only penalize time beyond 30 seconds per attempt
        let reasonableTimePerAttempt = 30.0
        let reasonableTime = Double(attempts) * reasonableTimePerAttempt
        let timeOverage = max(0, timeElapsed - reasonableTime)
        let timePenalty = Int(timeOverage / 5)  // Much gentler time penalty
        
        // Calculate base score with penalties
        var finalScore = baseScore - attemptPenalty - timePenalty
        
        // Significant bonuses for exceptional performance
        switch attempts {
        case 1:
            finalScore += 90  // Massive bonus for perfect guess
        case 2:
            finalScore += 40  // Large bonus for 2 attempts
        case 3:
            finalScore += 20  // Good bonus for 3 attempts
        case 4:
            finalScore += 10  // Small bonus for 4 attempts
        default:
            break
        }
        
        // Speed bonuses (but only significant for very fast times)
        if timeElapsed < Double(attempts * 20) {  // 20 seconds per attempt
            finalScore += 10
        }
        if timeElapsed < Double(attempts * 15) {  // 15 seconds per attempt
            finalScore += 50
        }
        
        // Ensure minimum score
        return max(finalScore, 10)
    }

    // MARK: - Private Methods
    private func saveToUserDefaults() {
        do {
            let data = try JSONEncoder().encode(allScores)
            userDefaults.set(data, forKey: scoresKey)
            print("💾 Saved \(allScores.count) scores to UserDefaults")
        } catch {
            print("❌ Failed to save scores: \(error)")
        }
    }

    private func loadScores() {
        guard let data = userDefaults.data(forKey: scoresKey) else {
            print("📂 No existing scores found")
            return
        }
        do {
            allScores = try JSONDecoder().decode([GameScore].self, from: data)
            print("📂 Loaded \(allScores.count) scores from UserDefaults")
        } catch {
            print("❌ Failed to load scores: \(error)")
            allScores = []
        }
    }

    func clearAllScores() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.allScores.removeAll()
            self.saveToUserDefaults()
            self.objectWillChange.send()
        }
    }
    
    func getMostRecentScore(for gameId: String) -> GameScore? {
        return allScores
            .filter { $0.gameId == gameId }
            .sorted { $0.date > $1.date }  // Sort by date, newest first
            .first
    }
    
    // Add these methods to your GameScoreManager class

    func markGameCompleted(gameId: String, date: Date) {
        // Normalize to UTC start of day
        let utcCalendar = Calendar(identifier: .gregorian)
        var calendar = utcCalendar
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let startOfDayUTC = calendar.startOfDay(for: date)
        
        // Use ISO yyyy-MM-dd string in UTC
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let dateString = formatter.string(from: startOfDayUTC)
        
        let key = "completed_\(gameId)_\(dateString)"
        UserDefaults.standard.set(true, forKey: key)
        
        print("✅ markGameCompleted: \(UserDefaults.standard.bool(forKey: key)) for \(key)")
        objectWillChange.send()
    }



    func isGameCompleted(gameId: String, date: Date) -> Bool {
        let utcCalendar = Calendar(identifier: .gregorian)
        var calendar = utcCalendar
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let startOfDayUTC = calendar.startOfDay(for: date)
        //print("❓ isGameCompleted(): date in: \(date)")
        //print(" ➠ isGameCompleted(): startOfDayUTC: \(startOfDayUTC)")
        
        let thisFormatter = DateFormatter()
        thisFormatter.dateFormat = "yyyy-MM-dd"
        thisFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        thisFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let dateString = thisFormatter.string(from: startOfDayUTC)
        
        //print(" ➠ isGameCompleted(): dateString: \(dateString)")
        
        let key = "completed_\(gameId)_\(dateString)"
        
        //print(" ❓ isGameCompleted() for key: \(key)")
        
        //print("isGameCompleted: \(UserDefaults.standard.bool(forKey: key)) for \(key)")
        return UserDefaults.standard.bool(forKey: key)
    }
    
    func debugGameCompletion(gameId: String, date: Date) {
        let utcCalendar = Calendar(identifier: .gregorian)
        var calendar = utcCalendar
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let startOfDayUTC = calendar.startOfDay(for: date)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let dateString = formatter.string(from: startOfDayUTC)
        
        let key = "completed_\(gameId)_\(dateString)"
        let isCompleted = UserDefaults.standard.bool(forKey: key)
        
        print("""
        🔍 GAME COMPLETION DEBUG for \(gameId):
        - Input date: \(date)
        - UTC start of day: \(startOfDayUTC)
        - Date string: \(dateString)
        - UserDefaults key: \(key)
        - Stored value: \(isCompleted)
        - Current timezone: \(TimeZone.current.identifier)
        """)
    }

    func clearAllCompletionStatus() {
        let userDefaults = UserDefaults.standard
        let allKeys = userDefaults.dictionaryRepresentation().keys
        
        // Find all completion keys (they start with "completed_")
        let completionKeys = allKeys.filter { $0.hasPrefix("completed_") }
        
        print("🗑️ Clearing \(completionKeys.count) completion status entries:")
        
        // Remove each completion key
        for key in completionKeys {
            userDefaults.removeObject(forKey: key)
            print("   - Removed: \(key)")
        }
        
        // Force UserDefaults to save immediately
        userDefaults.synchronize()
        
        print("✅ All completion status cleared")
        
        // Notify observers that the state changed
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    // Alternative: Clear completion status for a specific game only
    func clearCompletionStatus(for gameId: String) {
        let userDefaults = UserDefaults.standard
        let allKeys = userDefaults.dictionaryRepresentation().keys
        
        // Find completion keys for this specific game
        let gameCompletionKeys = allKeys.filter { $0.hasPrefix("completed_\(gameId)_") }
        
        print("🗑️ Clearing \(gameCompletionKeys.count) completion entries for \(gameId):")
        
        for key in gameCompletionKeys {
            userDefaults.removeObject(forKey: key)
            print("   - Removed: \(key)")
        }
        
        userDefaults.synchronize()
        print("✅ Completion status cleared for \(gameId)")
        
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    // Alternative: Clear completion status for a specific date across all games
    func clearCompletionStatus(for date: Date) {
        let utcCalendar = Calendar(identifier: .gregorian)
        var calendar = utcCalendar
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let startOfDayUTC = calendar.startOfDay(for: date)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let dateString = formatter.string(from: startOfDayUTC)
        
        let userDefaults = UserDefaults.standard
        let allKeys = userDefaults.dictionaryRepresentation().keys
        
        // Find completion keys for this specific date
        let dateCompletionKeys = allKeys.filter { $0.contains("_\(dateString)") && $0.hasPrefix("completed_") }
        
        print("🗑️ Clearing \(dateCompletionKeys.count) completion entries for \(dateString):")
        
        for key in dateCompletionKeys {
            userDefaults.removeObject(forKey: key)
            print("   - Removed: \(key)")
        }
        
        userDefaults.synchronize()
        print("✅ Completion status cleared for \(dateString)")
        
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
}
