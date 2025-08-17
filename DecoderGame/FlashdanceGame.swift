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

    // MARK: - Gameplay
    @Published var currentEquation: String = ""
    @Published var answers: [Int] = []
    @Published var correctAnswer: Int = 0
    @Published var attempts: Int = 0   // use as "score" (correct answers)

    // MARK: - Timers / phases
    @Published var countdownValue: Int = 3          // 3…2…1 pre-round
    @Published var gameTimeRemaining: Int = 30      // main game timer (sec)
    @Published var isPreCountdownActive: Bool = false
    @Published var isGameActive: Bool = false

    private var preCountdownTimer: Timer?
    private var gameTimer: Timer?
    private var roundStart: Date?
    
    let gameInfo = GameInfo(
           id: "flashdance",
           displayName: "flashdance",
           description: "math flashcard fun",
           isAvailable: true,
           gameLocation: FlashdanceGameView()
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
        attempts = 0
        statusText = "Get ready…"
        countdownValue = 3
        isPreCountdownActive = true
        isGameActive = false
        roundStart = nil

        // Pre-generate the first question so we're ready the moment play starts.
        newQuestion()

        print("FlashdanceGame started with scoreManager: \(type(of: scoreManager))")

        preCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self = self else { return }
            if self.countdownValue > 1 {
                self.countdownValue -= 1
            } else {
                t.invalidate()
                self.isPreCountdownActive = false
                self.startMainGame()
            }
        }
    }

    func resetGame() { startGame() }

    func endGame() {
        stopAllTimers()
        isGameActive = false
        isPreCountdownActive = false
        gameOver = 1
        
        // Update the display with final score
        statusText = "Game over!"
        currentEquation = "Final\nScore\n\n\(attempts)"

        print("Game ended. Saving score: \(attempts) to \(type(of: scoreManager))")
        
        // --- Save score to ScoreManager ---
        let timeElapsed = roundStart != nil ? Date().timeIntervalSince(roundStart!) : 30.0
        let newScore = GameScore(
            gameId: "flashdance",
            date: Date(),
            attempts: attempts,
            timeElapsed: timeElapsed,
            won: true,  // In Flashdance, finishing the game is always a "win"
            finalScore: attempts  // Score is the number of correct answers
        )
        
        scoreManager.saveScore(newScore)
        print("Score saved successfully: \(attempts) points")
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
        statusText = "Swipe toward the correct answer!"
    }

    func checkAnswer(selected: Int) -> Bool {
        let isCorrect = selected == correctAnswer
        if isCorrect {
            attempts += 1
            statusText = "✅ Correct! (\(attempts))"
        } else {
            statusText = "❌ Try again!"
        }
        return isCorrect
    }

    // MARK: - Private

    private func startMainGame() {
        gameTimeRemaining = 30
        isGameActive = true
        statusText = "Go!"
        roundStart = Date()  // Track when the actual game started

        gameTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self = self else { return }
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
