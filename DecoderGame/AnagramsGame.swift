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
    @Published var lastScore: GameScore?

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
    @Published var isGamePaused: Bool = false       // Track pause state

    private var preCountdownTimer: Timer?
    private var gameTimer: Timer?
    private var roundStart: Date?

    let gameInfo = GameInfo(
        id: "anagrams",
        displayName: "letters",
        description: "rearrange letters into words",
        isAvailable: true,
        gameLocation: AnyView(EmptyView()), // replace with real view if needed
        gameIcon: Image(systemName: "60.arrow.trianglehead.clockwise")
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
    }

    // MARK: - Public API

    func startGame() {
        stopAllTimers()
        gameOver = 0
        attempts = 0
        isGamePaused = false
        userAnswer = ""
        usedLetterIndices = []
        statusText = "Get ready…"
        countdownValue = 3
        isPreCountdownActive = true
        isGameActive = false
        roundStart = nil
        lastScore = nil

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

    func pauseGame() {
        guard !isGamePaused else { return }
        isGamePaused = true
    }

    func resumeGame() {
        guard isGamePaused else { return }
        isGamePaused = false
    }

    func resetGame() { startGame() }

    func endGame() {
        stopAllTimers()
        isGameActive = false
        isPreCountdownActive = false
        isGamePaused = false
        gameOver = 1
        
        // Update display
        statusText = "Game over!"
        currentWord = "Final\nScore\n\n\(attempts)"
        scrambledLetters = []
        usedLetterIndices = []
        userAnswer = ""
        
        // Compute longest word length (simple example: currentWord's length)
        let longestWordLength = currentWord.count
        
        // Save score to ScoreManager
        let newScore = GameScore(
            gameId: "anagrams",
            date: Date(),
            attempts: attempts,
            timeElapsed: 60.0,
            won: true,
            finalScore: attempts,
            additionalProperties: AnagramsAdditionalProperties(
                gameDuration: 60.0,
                longestWord: longestWordLength
            )
        )
        
        scoreManager.saveScore(newScore)
        lastScore = newScore  // save locally for display
        print("Score saved successfully: \(attempts) points")
    }


    // MARK: - Gameplay helpers

    func newQuestion() {
        currentWord = wordList.randomElement() ?? "SWIFT"
        scrambledLetters = currentWord.map { String($0) }.shuffled()
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
        
        if usedLetterIndices.count == scrambledLetters.count {
            checkAnswer()
        }
    }
    
    func removeLetter(at index: Int) {
        guard index < userAnswer.count else { return }
        let letterIndex = userAnswer.index(userAnswer.startIndex, offsetBy: index)
        let letter = String(userAnswer[letterIndex])
        userAnswer.remove(at: letterIndex)
        
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
            statusText = "Correct! (\(attempts))"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.newQuestion()
            }
        } else {
            statusText = "Wrong! Try again."
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.usedLetterIndices.removeAll()
                self.userAnswer = ""
            }
        }
    }

    // MARK: - Private

    private func startMainGame() {
        gameTimeRemaining = 60
        isGameActive = true
        statusText = "Go!"
        roundStart = Date()

        gameTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self = self else { return }
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
    }
}
