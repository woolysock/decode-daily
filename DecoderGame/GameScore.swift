//
//  ScoreManager.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/14/25.
//

import Foundation

struct GameScore: Codable, Identifiable {
    let id: UUID
    let gameId: String           // "decode", "numbers", etc.
    let date: Date
    let attempts: Int            // Number of tries/turns
    let timeElapsed: TimeInterval // Seconds to complete
    let won: Bool               // Did they win or run out of attempts?
    let finalScore: Int         // Calculated score (higher = better)
    
    // Custom initializer to generate UUID
    init(gameId: String, date: Date, attempts: Int, timeElapsed: TimeInterval, won: Bool, finalScore: Int) {
        self.id = UUID()
        self.gameId = gameId
        self.date = date
        self.attempts = attempts
        self.timeElapsed = timeElapsed
        self.won = won
        self.finalScore = finalScore
    }
    
    // Computed properties for display
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

class ScoreManager: ObservableObject {
    @Published var allScores: [GameScore] = []
    
    private let userDefaults = UserDefaults.standard
    private let scoresKey = "SavedGameScores"
    
    init() {
        loadScores()
    }
    
    // Save a new score
    func saveScore(_ score: GameScore) {
        allScores.append(score)
        saveToUserDefaults()
    }
    
    // Get scores for a specific game, sorted by score (best first)
    func getScores(for gameId: String) -> [GameScore] {
        return allScores
            .filter { $0.gameId == gameId }
            .sorted { $0.finalScore > $1.finalScore }
    }
    
    // Get top scores across all games
    func getTopScores(limit: Int = 10) -> [GameScore] {
        return allScores
            .sorted { $0.finalScore > $1.finalScore }
            .prefix(limit)
            .map { $0 }
    }
    
    // Get recent scores
    func getRecentScores(limit: Int = 5) -> [GameScore] {
        return allScores
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .map { $0 }
    }
    
    // Calculate score for Decode game
    static func calculateDecodeScore(attempts: Int, timeElapsed: TimeInterval, won: Bool, maxAttempts: Int = 8) -> Int {
        guard won else { return 0 } // No points if you didn't win
        
        // Base score starts at 1000
        var score = 1000
        
        // Deduct points for attempts (fewer attempts = higher score)
        let attemptPenalty = (attempts - 1) * 100 // -100 per extra attempt
        score -= attemptPenalty
        
        // Deduct points for time (faster = higher score)
        let timePenalty = Int(timeElapsed / 10) // -1 point per 10 seconds
        score -= timePenalty
        
        // Bonus for winning quickly
        if attempts == 1 {
            score += 500 // Perfect game bonus
        } else if attempts <= 3 {
            score += 200 // Quick solve bonus
        }
        
        return max(score, 50) // Minimum score of 50 for any win
    }
    
    // MARK: - Private Methods
    
    private func saveToUserDefaults() {
        do {
            let data = try JSONEncoder().encode(allScores)
            userDefaults.set(data, forKey: scoresKey)
        } catch {
            print("Failed to save scores: \(error)")
        }
    }
    
    private func loadScores() {
        guard let data = userDefaults.data(forKey: scoresKey) else { return }
        
        do {
            allScores = try JSONDecoder().decode([GameScore].self, from: data)
        } catch {
            print("Failed to load scores: \(error)")
            allScores = []
        }
    }
    
    // Clear all scores (for testing or reset functionality)
    func clearAllScores() {
        allScores.removeAll()
        saveToUserDefaults()
    }
}
