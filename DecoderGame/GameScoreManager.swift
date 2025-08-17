//
//  GameScoreManager.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/14/25.
//

import Foundation
import SwiftUI

struct GameScore: Codable, Identifiable, Equatable {
    let id: UUID
    let gameId: String           // "flashdance", "decode", "numbers", "anagrams"
    let date: Date
    let attempts: Int            // Number of tries/turns
    let timeElapsed: TimeInterval // Seconds to complete
    let won: Bool                // Did they win?
    let finalScore: Int          // Calculated score (higher = better)

    // MARK: - Init
    init(gameId: String, date: Date, attempts: Int, timeElapsed: TimeInterval, won: Bool, finalScore: Int) {
        self.id = UUID()
        self.gameId = gameId
        self.date = date
        self.attempts = attempts
        self.timeElapsed = timeElapsed
        self.won = won
        self.finalScore = finalScore
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
    static func calculateDecodeScore(attempts: Int, timeElapsed: TimeInterval, won: Bool, maxAttempts: Int = 8) -> Int {
        guard won else { return 0 }

        var score = 1000
        score -= (attempts - 1) * 100
        score -= Int(timeElapsed / 10)

        if attempts == 1 {
            score += 500
        } else if attempts <= 3 {
            score += 200
        }

        return max(score, 50)
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
}
