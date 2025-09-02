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
    @Published var statusText: String = "\n\n\n"
    @Published var lastScore: GameScore?
    let targetDate: Date?

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
    private var cancellables = Set<AnyCancellable>()
    
    // Daily equation set manager - use singleton
    private let equationManager: DailyEquationManager
    
    // Daily equation specific
    @Published var dailyEquationSet: DailyEquationSet?
    @Published var currentEquationIndex: Int = 0
    @Published var equationsCompleted: Int = 0
    @Published var totalEquationsInSet: Int = 0
    @Published var isEquationSetCompleted: Bool = false
    
    let gameInfo = GameInfo(
        id: "flashdance",
        displayName: "Flashdance",
        description: "math flashcard fun",
        isAvailable: true,
        //gameLocation: AnyView(FlashdanceGameView()),
        gameIcon: Image(systemName: "30.arrow.trianglehead.clockwise")
    )

    // Initialize with score manager
    init(scoreManager: GameScoreManager, targetDate: Date? = nil) {
        self.scoreManager = GameScoreManager.shared
        self.equationManager = DailyEquationManager.shared
        self.targetDate = targetDate
        
        print("FlashdanceGame initialized with scoreManager: \(type(of: scoreManager))")
        
        // Observe equation manager changes
        equationManager.$currentEquationSet
            .receive(on: DispatchQueue.main)
            .sink { [weak self] equationSet in
                self?.dailyEquationSet = equationSet
            }
            .store(in: &cancellables)
       
    }
    
    // MARK: - Public API

    /// Call this to begin a fresh round (will run 3-2-1 first, then 30s game).
    func startGame() {
        print("🚀 FlashdanceGame.startGame() called")
        
        let gameDate = targetDate ?? Date()
        print("🎯 TARGET DATE DEBUG:")
        print("   - targetDate: \(String(describing: targetDate))")
        print("   - Current Date(): \(Date())")
        print("   - gameDate (final): \(gameDate)")
        print("   - gameDate formatted: \(DateFormatter.debugFormatter.string(from: gameDate))")
        
        // Debug: Check what the equation manager thinks about this date
        print("🔍 Before calling getTodaysEquationSet:")
        print("   - equationManager.currentEquationSet date: \(String(describing: equationManager.currentEquationSet?.date))")
        
        guard let todaysEquationSet = equationManager.getTodaysEquationSet(for: gameDate) else {
            print(" ❌ startGame(): No equation set available for date: \(gameDate)")
            statusText = "No equations available for this date!"
            return
        }
        
        print("✅ Got equation set for date: \(todaysEquationSet.date)")
        print("   - Requested date: \(gameDate)")
        print("   - Returned set date: \(todaysEquationSet.date)")
        print("   - Are they the same day? \(Calendar.current.isDate(gameDate, inSameDayAs: todaysEquationSet.date))")
        
        dailyEquationSet = todaysEquationSet
        totalEquationsInSet = todaysEquationSet.equations.count
        
        stopAllTimers()
        gameOver = 0
        correctAttempts = 0
        incorrectAttempts = 0
        currentStreak = 0
        maxStreak = 0
        totalScore = 0
        currentEquationIndex = 0
        equationsCompleted = 0
        isEquationSetCompleted = false
        isGamePaused = false
        statusText = "Get ready…"
        countdownValue = 3
        isPreCountdownActive = true
        isGameActive = false
        roundStart = nil
        lastScore = nil

        // Load the first equation
        newQuestion()

        preCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self = self else { return }
            
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

    func endGame(completion: (() -> Void)? = nil) {
        stopAllTimers()
        isGameActive = false
        isPreCountdownActive = false
        isGamePaused = false
        gameOver = 1

        calculateFinalScore()
        statusText = "Game over!"

        // Save score with targetDate as archiveDate
        scoreManager.saveFlashdanceScore(
            date: Date(),                        // actual play date
            archiveDate: targetDate,             // target/archived date
            attempts: correctAttempts + incorrectAttempts,
            timeElapsed: 30.0,
            finalScore: totalScore,
            gameDuration: 30,
            correctAnswers: correctAttempts,
            incorrectAnswers: incorrectAttempts,
            longestStreak: maxStreak,
            gameDate: targetDate ?? Date()
        )

        // Update lastScore after save completes on main thread
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.lastScore = self.scoreManager.getMostRecentScore(for: "flashdance")
            completion?()  // Call completion after lastScore is updated
        }

        //print("Score saved successfully: \(totalScore) points, \(correctAttempts) correct, \(incorrectAttempts) wrong")
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
        
        //print("Score breakdown - Base: \(baseScore), Penalty: -\(penalty), Streak: +\(streakBonus), Accuracy: +\(accuracyBonus), Final: \(totalScore)")
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
        print("🎲 newQuestion() called")
        print("   - currentEquationIndex: \(currentEquationIndex)")
        print("   - dailyEquationSet exists: \(dailyEquationSet != nil)")
        print("   - dailyEquationSet equation count: \(dailyEquationSet?.equations.count ?? 0)")
        
        guard let equationSet = dailyEquationSet,
              currentEquationIndex < equationSet.equations.count else {
            print("❌ newQuestion() guard failed - no more equations or no set available")
            // Continue with current equation or generate random fallback
            generateFallbackQuestion()
            return
        }
        
        let dailyEquation = equationSet.equations[currentEquationIndex]
        currentEquation = dailyEquation.expression
        correctAnswer = dailyEquation.answer
        
        print("✅ newQuestion() set equation to: '\(currentEquation)' = \(correctAnswer)")
        
        // Build 2 unique wrong answers near the correct one
        var options = Set([correctAnswer])
        while options.count < 3 {
            let jitter = Int.random(in: -10...10)
            let wrong = max(0, correctAnswer + jitter) // keep non-negative
            options.insert(wrong)
        }
        answers = Array(options).shuffled()
        statusText = "Swipe toward the correct answer!\n\n\n"
        
        print("✅ newQuestion() completed - answers: \(answers)")
    }

    // Fallback for when daily equations aren't available
    private func generateFallbackQuestion() {
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
        statusText = "Swipe toward the correct answer!\n\n"
    }

    func checkAnswer(selected: Int) -> Bool {
        let isCorrect = selected == correctAnswer
        if isCorrect {
            correctAttempts += 1
            equationsCompleted += 1
            currentStreak += 1
            maxStreak = max(maxStreak, currentStreak)
            
            // Advance to next equation in the daily set
            currentEquationIndex += 1
            
            updateRunningScore()
            
            // Enhanced status text with streak info
            var message = "Correct!\n"
            if currentStreak >= 3 {
                message += "\n\n🔥 streak \(currentStreak)! 🔥"  // Show streak with fire emoji
            } else {
                message += "\n\n🙌"
            }
            //message += " Score: \(totalScore)"
            statusText = message
            
        } else {
            incorrectAttempts += 1
            currentStreak = 0  // Reset streak on wrong answer
            
            // Still advance to next equation even if wrong (for variety during 30 seconds)
            currentEquationIndex += 1
            
            updateRunningScore()
            
            statusText = "❌ Wrong!\n\nTry Again. . .\n"
        }
        return isCorrect
    }

    // MARK: - Private

    private func startMainGame() {
        gameTimeRemaining = 30
        isGameActive = true
        statusText = "Go!\n\n\n"
        roundStart = Date()  // Track when the actual game started

        gameTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self = self else { return }
            
            // Don't decrement timer if paused
            if self.isGamePaused { return }
            
            if self.gameTimeRemaining > 0 {
                self.gameTimeRemaining -= 1
            } else {
                t.invalidate()
                self.endGame()  // This will now properly update lastScore before showing overlay
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

