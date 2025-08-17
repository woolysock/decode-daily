//
//  AnagramsGame.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/17/25.
//

import SwiftUI
import Combine

class AnagramsGame: GameProtocol, ObservableObject {
    // Make scoreManager mutable so it can be injected after initialization
    var scoreManager: GameScoreManager

    // MARK: - GameProtocol basics
    @Published var gameOver: Int = 0
    @Published var statusText: String = ""

    // MARK: - Gameplay
    @Published var currentWord: String = ""
    @Published var scrambledLetters: [String] = []
    @Published var usedLetterIndices: Set<Int> = []  // Track which letters are used
    @Published var userAnswer: String = ""
    @Published var attempts: Int = 0   // use as "score" (correct answers)
    @Published var currentLetterIndex: Int = 0  // for letter selection UI

    // MARK: - Timers / phases
    @Published var countdownValue: Int = 3          // 3…2…1 pre-round
    @Published var gameTimeRemaining: Int = 60      // main game timer (sec)
    @Published var isPreCountdownActive: Bool = false
    @Published var isGameActive: Bool = false

    private var preCountdownTimer: Timer?
    private var gameTimer: Timer?
    private var roundStart: Date?

    let gameInfo = GameInfo(
           id: "anagrams",
           displayName: "letters",
           description: "rearrange letters into words",
           isAvailable: true,
           gameLocation: AnagramsGameView()
       )

    // Word list for anagrams
    private let wordList = [
        "SWIFT", "APPLE", "PHONE", "GAMES", "MUSIC", "VIDEO", "PHOTO", "EMAIL",
        "BRAVE", "DREAM", "MAGIC", "SPACE", "TIGER", "OCEAN", "BEACH", "HOUSE",
        "LIGHT", "POWER", "WORLD", "HAPPY", "SMILE", "PEACE", "HEART", "ANGEL",
        "CLOUD", "STORM", "RIVER", "GLASS", "STONE", "PAINT", "TOWER", "CROWN",
        "QUEEN", "PRIZE", "CRAZY", "FLASH", "SUPER", "ROYAL", "FLAME", "STAR"
    ]

    // Initialize with score manager
    init(scoreManager: GameScoreManager) {
        self.scoreManager = scoreManager
        print("AnagramsGame initialized with scoreManager: \(type(of: scoreManager))")
    }
    

    // MARK: - Public API

    /// Call this to begin a fresh round (will run 3-2-1 first, then 60s game).
    func startGame() {
        stopAllTimers()
        gameOver = 0
        attempts = 0
        userAnswer = ""
        usedLetterIndices = []
        statusText = "Get ready…"
        countdownValue = 3
        isPreCountdownActive = true
        isGameActive = false
        roundStart = nil

        // Pre-generate the first question so we're ready the moment play starts.
        newQuestion()

        print("AnagramsGame started with scoreManager: \(type(of: scoreManager))")

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
        currentWord = "Final\nScore\n\n\(attempts)"
        scrambledLetters = []
        usedLetterIndices = []
        userAnswer = ""

        print("Game ended. Saving score: \(attempts) to \(type(of: scoreManager))")
        
        // --- Save score to ScoreManager ---
        let timeElapsed = roundStart != nil ? Date().timeIntervalSince(roundStart!) : 60.0
        let newScore = GameScore(
            gameId: "anagrams",
            date: Date(),
            attempts: attempts,
            timeElapsed: timeElapsed,
            won: true,  // In Anagrams, finishing the game is always a "win"
            finalScore: attempts  // Score is the number of correct answers
        )
        
        scoreManager.saveScore(newScore)
        print("Score saved successfully: \(attempts) points")
    }
    
    // MARK: - Gameplay helpers

    func newQuestion() {
        // Pick a random word
        currentWord = wordList.randomElement() ?? "SWIFT"
        
        // Scramble the letters
        scrambledLetters = currentWord.map { String($0) }.shuffled()
        
        // Make sure it's actually scrambled (not the same as original)
        while scrambledLetters.joined() == currentWord && currentWord.count > 1 {
            scrambledLetters.shuffle()
        }
        
        userAnswer = ""
        usedLetterIndices = []
        currentLetterIndex = 0
        statusText = "Unscramble the letters to form a word!"
    }

    func selectLetter(at index: Int) {
        guard index < scrambledLetters.count && !usedLetterIndices.contains(index) else { return }
        userAnswer += scrambledLetters[index]
        usedLetterIndices.insert(index)
        
        // Check if word is complete
        if usedLetterIndices.count == scrambledLetters.count {
            checkAnswer()
        }
    }
    
    func removeLetter(at index: Int) {
        guard index < userAnswer.count else { return }
        let letterIndex = userAnswer.index(userAnswer.startIndex, offsetBy: index)
        let letter = String(userAnswer[letterIndex])
        userAnswer.remove(at: letterIndex)
        
        // Find the corresponding index in scrambled letters and mark as unused
        if let scrambledIndex = scrambledLetters.firstIndex(where: { $0 == letter && usedLetterIndices.contains(scrambledLetters.firstIndex(of: $0) ?? -1) }) {
            usedLetterIndices.remove(scrambledIndex)
        }
    }
    
    func clearAnswer() {
        usedLetterIndices.removeAll()
        userAnswer = ""
    }

    private func checkAnswer() {
        let isCorrect = userAnswer.uppercased() == currentWord.uppercased()
        if isCorrect {
            attempts += 1
            statusText = "✅ Correct! (\(attempts))"
            
            // Brief pause before next question
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.newQuestion()
            }
        } else {
            statusText = "❌ Wrong! Try again."
            // Return letters to available state
            usedLetterIndices.removeAll()
            userAnswer = ""
        }
    }

    // MARK: - Private

    private func startMainGame() {
        gameTimeRemaining = 60
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
        print("AnagramsGame deinitialized")
    }
}
