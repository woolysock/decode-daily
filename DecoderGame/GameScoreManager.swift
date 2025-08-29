//
//  GameScoreManager.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/14/25.
//

import Foundation
import SwiftUI

// MARK: - Game-specific additional properties structures
struct FlashdanceAdditionalProperties: Codable {
    let gameDuration: Int        // Duration in seconds
    let correctAnswers: Int      // Number of correct answers
    let incorrectAnswers: Int    // Number of incorrect answers
    let longestStreak: Int       // Longest consecutive correct streak
}

struct DecodeAdditionalProperties: Codable {
    let gameDuration: TimeInterval // Duration of the game
    let turnsToSolve: Int         // Number of turns taken to solve
    let codeLength: Int           // Number of squares in the code
}

//MOVED TO THE GAME CODE
//struct AnagramsAdditionalProperties: Codable {
//    let gameDuration: TimeInterval // Duration of the game
//    let longestWord: Int
//    let totalWordsInSet: Int
//}

// MARK: - Enhanced GameScore with additional properties
struct GameScore: Codable, Identifiable, Equatable {
    let id: UUID
    let gameId: String           // "flashdance", "decode", "numbers", "anagrams"
    let date: Date
    let attempts: Int            // Number of tries/turns
    let timeElapsed: TimeInterval // Seconds to complete
    let won: Bool                // Did they win?
    let finalScore: Int          // Calculated score (higher = better)
    
    // NEW: Additional game-specific properties stored as JSON data
    let additionalPropertiesData: Data?

    // MARK: - Init (backwards compatible)
    init(gameId: String, date: Date, attempts: Int, timeElapsed: TimeInterval, won: Bool, finalScore: Int) {
        self.id = UUID()
        self.gameId = gameId
        self.date = date
        self.attempts = attempts
        self.timeElapsed = timeElapsed
        self.won = won
        self.finalScore = finalScore
        self.additionalPropertiesData = nil
    }
    
    // MARK: - Init with additional properties
    init(gameId: String, date: Date, attempts: Int, timeElapsed: TimeInterval, won: Bool, finalScore: Int, additionalProperties: Codable?) {
        self.id = UUID()
        self.gameId = gameId
        self.date = date
        self.attempts = attempts
        self.timeElapsed = timeElapsed
        self.won = won
        self.finalScore = finalScore
        
        // Encode additional properties to Data
        if let properties = additionalProperties {
            do {
                self.additionalPropertiesData = try JSONEncoder().encode(properties)
            } catch {
                print("❌ Failed to encode additional properties: \(error)")
                self.additionalPropertiesData = nil
            }
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
    // ADDED: Singleton instance
    static let shared = GameScoreManager()
    
    @Published var allScores: [GameScore] = []

    private let userDefaults = UserDefaults.standard
    private let scoresKey = "SavedGameScores"

    // MODIFIED: Made init private to enforce singleton pattern
    private init() {
        loadScores()
    }

    // MARK: - Enhanced Save Methods
    
    // Save a new score - FIXED to ensure main thread updates
    func saveScore(_ score: GameScore) {
        print("🔄 About to save score: \(score.finalScore) for \(score.gameId)")
        
        // Ensure UI updates happen on the main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.allScores.append(score)
            self.saveToUserDefaults()
            
            print("✅ Score saved on main thread! Total scores: \(self.allScores.count)")
            print("✅ Scores for \(score.gameId): \(self.allScores.filter { $0.gameId == score.gameId }.count)")
            
            // Force an additional UI update notification
            self.objectWillChange.send()
        }
    }
    
    // MARK: - Convenience Save Methods for Specific Games
    

    /// Save a Flashdance score with additional properties
    func saveFlashdanceScore(
        date: Date = Date(),
        attempts: Int,
        timeElapsed: TimeInterval,
        finalScore: Int,
        gameDuration: Int,
        correctAnswers: Int,
        incorrectAnswers: Int,
        longestStreak: Int
    ) {
        let additionalProps = FlashdanceAdditionalProperties(
            gameDuration: gameDuration,
            correctAnswers: correctAnswers,
            incorrectAnswers: incorrectAnswers,
            longestStreak: longestStreak
        )
        
        let score = GameScore(
            gameId: "flashdance",
            date: date,
            attempts: attempts,
            timeElapsed: timeElapsed,
            won: true, // Flashdance is always a "win" when completed
            finalScore: finalScore,
            additionalProperties: additionalProps
        )
        
        saveScore(score)
    }
    
    /// Save a Decode score with additional properties
    func saveDecodeScore(
        date: Date = Date(),
        attempts: Int,
        timeElapsed: TimeInterval,
        won: Bool,
        finalScore: Int,
        turnsToSolve: Int,
        codeLength: Int
    ) {
        let additionalProps = DecodeAdditionalProperties(
            gameDuration: timeElapsed,
            turnsToSolve: turnsToSolve,
            codeLength: codeLength
        )
        
        let score = GameScore(
            gameId: "decode",
            date: date,
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
        
        print("📊 getScores for '\(gameId)': found \(filteredScores.count) scores")
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
        
        let baseScore = 1000
        
        // Heavy penalty for more attempts (this should be the primary factor)
        let attemptPenalty = (attempts - 1) * 150  // Increased from 100
        
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
            finalScore += 800  // Massive bonus for perfect guess
        case 2:
            finalScore += 400  // Large bonus for 2 attempts
        case 3:
            finalScore += 200  // Good bonus for 3 attempts
        case 4:
            finalScore += 100  // Small bonus for 4 attempts
        default:
            break
        }
        
        // Speed bonuses (but only significant for very fast times)
        if timeElapsed < Double(attempts * 15) {  // 15 seconds per attempt
            finalScore += 100
        }
        if timeElapsed < Double(attempts * 10) {  // 10 seconds per attempt
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
}
