//
//  FlashdanceGame.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/12/25.
//

import SwiftUI
import Combine

enum AnswerPosition: CaseIterable { case left, top, right }

class FlashdanceGame: GameProtocol, ObservableObject {
    // Make scoreManager mutable so it can be injected after initialization
    var scoreManager: GameScoreManager

    // MARK: - GameProtocol basics
    @Published var gameOver: Int = 0
    @Published var statusText: String = ""
    @Published var lastScore: GameScore?

    // MARK: - Gameplay
    @Published var currentEquation: String = ""
    @Published var answers: [Int] = []
    @Published var correctAnswer: Int = 0
    @Published var correctAttempts: Int = 0      // Correct answers
    @Published var incorrectAttempts: Int = 0    // NEW: Incorrect answers
    @Published var currentStreak: Int = 0        // NEW: Current consecutive correct streak
    @Published var maxStreak: Int = 0           // NEW: Best streak this game
    @Published var totalScore: Int = 0          // NEW: Running calculated score

    // MARK: - Timers / phases
    @Published var countdownValue: Int = 3          // 3…2…1 pre-round
    @Published var gameTimeRemaining: Int = 30      // main game timer (sec)
    @Published var isPreCountdownActive: Bool = false
    @Published var isGameActive: Bool = false
    @Published var isGamePaused: Bool = false       // NEW: Track pause state

    private var preCountdownTimer: Timer?
    private var gameTimer: Timer?
    private var roundStart: Date?
    
    let gameInfo = GameInfo(
           id: "flashdance",
           displayName: "flashdance",
           description: "math flashcard fun",
           isAvailable: true,
           gameLocation: AnyView(FlashdanceGameView()),
           gameIcon: Image(systemName: "30.arrow.trianglehead.clockwise")
       )

    // Initialize with score manager
    init(scoreManager: GameScoreManager) {
        self.scoreManager = scoreManager
        print("FlashdanceGame initialized with scoreManager: \(type(of: scoreManager))")
    }

    // MARK: - Public API

    /// Call this to begin a fresh round (will run 3-2-1 first, then 30s game).
    func startGame() {
        stopAllTimers()
        gameOver = 0
        correctAttempts = 0
        incorrectAttempts = 0
        currentStreak = 0
        maxStreak = 0
        totalScore = 0
        isGamePaused = false  // Reset pause state
        statusText = "Get ready…"
        countdownValue = 3
        isPreCountdownActive = true
        isGameActive = false
        roundStart = nil
        lastScore = nil

        // Pre-generate the first question so we're ready the moment play starts.
        newQuestion()

        //print("FlashdanceGame started with scoreManager: \(type(of: scoreManager))")

        preCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self = self else { return }
            
            // Don't decrement countdown if paused
            if self.isGamePaused { return }
            
            if self.countdownValue > 1 {
                self.countdownValue -= 1
            } else {
                t.invalidate()
                self.isPreCountdownActive = false
                self.startMainGame()
            }
        }
    }

    /// NEW: Pause the game timers
    func pauseGame() {
        guard !isGamePaused else { return }
        isGamePaused = true
        print("Game paused")
    }

    /// NEW: Resume the game timers
    func resumeGame() {
        guard isGamePaused else { return }
        isGamePaused = false
        print("Game resumed")
    }

    func resetGame() { startGame() }

    func endGame() {
        stopAllTimers()
        isGameActive = false
        isPreCountdownActive = false
        isGamePaused = false
        gameOver = 1
        
        calculateFinalScore()
        statusText = "Game over!"
        
//        // Wrap extra stats in FlashdanceAdditionalProperties
//        let additionalProps = FlashdanceAdditionalProperties(
//            gameDuration: 30,                 // fixed duration in your game
//            correctAnswers: correctAttempts,
//            incorrectAnswers: incorrectAttempts,
//            longestStreak: maxStreak
//        )
        
        // Create GameScore directly
//        let final = GameScore(
//            gameId: "flashdance",
//            date: Date(),
//            attempts: correctAttempts + incorrectAttempts,
//            timeElapsed: 30.0,
//            won: true,                        // Flashdance is always "completed"
//            finalScore: totalScore,
//            additionalProperties: additionalProps
//        )
//        
//        // Assign so EndGameOverlay can use it
//        lastScore = final
//        
//        // Persist to manager if desired
//        scoreManager.saveScore(final)
        
        scoreManager.saveFlashdanceScore(
            attempts: correctAttempts + incorrectAttempts,
            timeElapsed: 30.0,
            finalScore: totalScore,
            gameDuration: 30,
            correctAnswers: correctAttempts,
            incorrectAnswers: incorrectAttempts,
            longestStreak: maxStreak
        )
        lastScore = scoreManager.getScores(for: "flashdance").first
        
        
        print("Score saved successfully: \(totalScore) points")
    }


    
    // MARK: - Scoring System
    
    private func calculateFinalScore() {
        // Base scoring: 10 points per correct answer
        let baseScore = correctAttempts * 10
        
        // Penalty for incorrect answers: -3 points each
        let penalty = incorrectAttempts * 3
        
        // Streak bonus: Award extra points for best streak
        let streakBonus = calculateStreakBonus(maxStreak)
        
        // Accuracy bonus: Extra points for high accuracy
        let accuracyBonus = calculateAccuracyBonus()
        
        totalScore = max(0, baseScore - penalty + streakBonus + accuracyBonus)
        
        print("Score breakdown - Base: \(baseScore), Penalty: -\(penalty), Streak: +\(streakBonus), Accuracy: +\(accuracyBonus), Final: \(totalScore)")
    }
    
    private func calculateStreakBonus(_ streak: Int) -> Int {
        switch streak {
        case 0...2: return 0
        case 3...4: return 5
        case 5...7: return 15
        case 8...10: return 30
        case 11...15: return 50
        default: return 75 // 16+ streak
        }
    }
    
    private func calculateAccuracyBonus() -> Int {
        let totalAttempts = correctAttempts + incorrectAttempts
        guard totalAttempts > 0 else { return 0 }
        
        let accuracy = Double(correctAttempts) / Double(totalAttempts)
        
        switch accuracy {
        case 0.95...1.0: return 25  // 95-100%
        case 0.90..<0.95: return 15 // 90-94%
        case 0.80..<0.90: return 10 // 80-89%
        case 0.70..<0.80: return 5  // 70-79%
        default: return 0           // Below 70%
        }
    }
    
    private func updateRunningScore() {
        // Update the running score display during gameplay
        let baseScore = correctAttempts * 10
        let penalty = incorrectAttempts * 3
        let streakBonus = calculateStreakBonus(currentStreak)
        
        totalScore = max(0, baseScore - penalty + streakBonus)
    }
    
    // MARK: - Gameplay helpers

    /// Randomly choose + or −. For subtraction, keep result ≥ 0.
    func newQuestion() {
        let a = Int.random(in: 1...20)
        let b = Int.random(in: 1...20)

        if Bool.random() {
            // Addition
            correctAnswer = a + b
            currentEquation = "\(a) + \(b)"
        } else {
            // Subtraction (non-negative)
            let hi = max(a, b)
            let lo = min(a, b)
            correctAnswer = hi - lo
            currentEquation = "\(hi) - \(lo)"
        }

        // Build 2 unique wrong answers near the correct one
        var options = Set([correctAnswer])
        while options.count < 3 {
            let jitter = Int.random(in: -10...10)
            let wrong = max(0, correctAnswer + jitter) // keep non-negative
            options.insert(wrong)
        }
        answers = Array(options).shuffled()
        statusText = "Swipe toward the correct answer! Score: \(totalScore)"
    }

    func checkAnswer(selected: Int) -> Bool {
        let isCorrect = selected == correctAnswer
        if isCorrect {
            correctAttempts += 1
            currentStreak += 1
            maxStreak = max(maxStreak, currentStreak)
            
            updateRunningScore()
            
            // Enhanced status text with streak info
            var message = "✅ Correct! (\(correctAttempts)/\(correctAttempts + incorrectAttempts))"
            if currentStreak >= 3 {
                message += " 🔥\(currentStreak)"  // Show streak with fire emoji
            }
            message += " Score: \(totalScore)"
            statusText = message
            
        } else {
            incorrectAttempts += 1
            currentStreak = 0  // Reset streak on wrong answer
            
            updateRunningScore()
            
            statusText = "❌ Wrong! (\(correctAttempts)/\(correctAttempts + incorrectAttempts)) Score: \(totalScore)"
        }
        return isCorrect
    }

    // MARK: - Private

    private func startMainGame() {
        gameTimeRemaining = 30
        isGameActive = true
        statusText = "Go! Score: \(totalScore)"
        roundStart = Date()  // Track when the actual game started

        gameTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self = self else { return }
            
            // Don't decrement timer if paused
            if self.isGamePaused { return }
            
            if self.gameTimeRemaining > 0 {
                self.gameTimeRemaining -= 1
            } else {
                t.invalidate()
                self.endGame()
            }
        }
    }

    private func stopAllTimers() {
        preCountdownTimer?.invalidate()
        gameTimer?.invalidate()
        preCountdownTimer = nil
        gameTimer = nil
    }

    deinit {
        stopAllTimers()
        print("FlashdanceGame deinitialized")
    }
}
