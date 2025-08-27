//
//  AnagramsGame.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/17/25.
//  Updated to use daily wordsets
//

import SwiftUI
import Combine

class AnagramsGame: GameProtocol, ObservableObject {
    // Make scoreManager mutable so it can be injected after initialization
    var scoreManager: GameScoreManager
    
    // Daily wordset manager - use singleton
    private let wordsetManager: DailyWordsetManager

    // MARK: - GameProtocol basics
    @Published var gameOver: Int = 0
    @Published var statusText: String = "unscramble the words"
    @Published var lastScore: GameScore?

    // MARK: - Gameplay
    @Published var currentWord: String = ""
    @Published var scrambledLetters: [String] = []
    @Published var usedLetterIndices: Set<Int> = []  // Track which letters are used
    @Published var userAnswer: String = ""
    @Published var attempts: Int = 0   // use as "score" (correct answers)
    @Published var currentLetterIndex: Int = 0  // for letter selection UI
    
    // Daily wordset specific
    @Published var dailyWordset: DailyWordset?
    @Published var currentWordIndex: Int = 0
    @Published var wordsCompleted: Int = 0
    @Published var totalWordsInSet: Int = 0
    @Published var isWordsetCompleted: Bool = false

    // MARK: - Timers / phases
    @Published var countdownValue: Int = 3          // 3…2…1 pre-round
    @Published var gameTimeRemaining: Int = 60      // main game timer (sec)
    @Published var isPreCountdownActive: Bool = false
    @Published var isGameActive: Bool = false
    @Published var isGamePaused: Bool = false       // Track pause state

    private var preCountdownTimer: Timer?
    private var gameTimer: Timer?
    private var roundStart: Date?
    private var cancellables = Set<AnyCancellable>()

    let gameInfo = GameInfo(
        id: "anagrams",
        displayName: "letters",
        description: "rearrange letters into words",
        isAvailable: true,
        gameLocation: AnyView(EmptyView()), // replace with real view if needed
        gameIcon: Image(systemName: "60.arrow.trianglehead.clockwise")
    )

    // Initialize with score manager and use singleton wordset manager
    init(scoreManager: GameScoreManager) {
        self.scoreManager = scoreManager
        self.wordsetManager = DailyWordsetManager.shared  // Use singleton
        
        print("AnagramsGame initialized with scoreManager: \(type(of: scoreManager))")
        
        // Observe wordset manager changes
        wordsetManager.$currentWordset
            .receive(on: DispatchQueue.main)
            .sink { [weak self] wordset in
                self?.dailyWordset = wordset
            }
            .store(in: &cancellables)
    }

    // MARK: - Public API

    func startGame() {
        print("🚀 AnagramsGame.startGame() called")
        
        // Debug: Check what the wordset manager thinks it has
            //print("🔍 Debugging wordset loading:")
            //print("   - wordsetManager.currentWordset: \(wordsetManager.currentWordset?.words ?? [])")
            
        
        // Load today's wordset
        guard let todaysWordset = wordsetManager.getTodaysWordset() else {
            print("startGame(): ❌ No wordset available - getTodaysWordset() returned nil")
            statusText = "No wordset available for today!"
            return
        }
        
        print("✅ startGame(): Got wordset with \(todaysWordset.words.count) words")
        print("📝 startGame(): Setting up game state...")
        
        dailyWordset = todaysWordset
        totalWordsInSet = todaysWordset.words.count
        
        print("🛑 startGame(): Stopping all timers...")
        stopAllTimers()
        
        print("🔄 startGame(): Resetting game variables...")
        gameOver = 0
        attempts = 0
        wordsCompleted = 0
        currentWordIndex = 0
        isWordsetCompleted = false
        isGamePaused = false
        userAnswer = ""
        usedLetterIndices = []
        roundStart = nil
        lastScore = nil

        print("🎲 startGame(): Calling newQuestion()...")
        newQuestion()

        // CRITICAL FIX: Ensure ALL UI updates happen on main thread together
        DispatchQueue.main.async {
            self.statusText = "Get ready…"
            self.countdownValue = 3
            self.isPreCountdownActive = true
            self.isGameActive = false
            
            //print("✅ Set UI state on main thread - isPreCountdownActive: \(self.isPreCountdownActive)")
            
            //print("⏱️ Starting pre-countdown timer...")
            self.preCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
                guard let self = self else {
                    print("❌ Timer callback: self is nil")
                    return
                }
                if self.isGamePaused {
                    print("⏸️ Timer callback: game is paused")
                    return
                }
                
                // Already on main thread since timer was created on main thread
                print("⏱️ Countdown: \(self.countdownValue)")
                
                if self.countdownValue > 1 {
                    self.countdownValue -= 1
                } else {
                    print("🏁 Countdown finished, invalidating timer and starting main game")
                    t.invalidate()
                    self.isPreCountdownActive = false
                    self.startMainGame()
                }
            }
        }
        
        print("✅ startGame(): completed setup")
    }
    
    func startGameWithWordset(_ wordset: DailyWordset) {
        print("startGameWithWordset: \(wordset)")
        dailyWordset = wordset
        totalWordsInSet = wordset.words.count
        
        stopAllTimers()
        gameOver = 0
        attempts = 0
        wordsCompleted = 0
        currentWordIndex = 0
        isWordsetCompleted = false
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
        DispatchQueue.main.async {
            self.preCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
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
        
        // Calculate final score and statistics
        let finalScore = wordsCompleted
        let longestWordLength = getLongestWordCompleted()
        let gameWon = wordsCompleted >= (totalWordsInSet / 2) // Consider winning if completed at least half
        
        // Update display
        statusText = gameWon ? "Well done!" : "Game over!"
        currentWord = "Final\nScore\n\n\(finalScore)/\(totalWordsInSet)"
        scrambledLetters = []
        usedLetterIndices = []
        userAnswer = ""
        
        // Save score to ScoreManager
        let newScore = GameScore(
            gameId: "anagrams",
            date: Date(),
            attempts: wordsCompleted,
            timeElapsed: 60.0,
            won: gameWon,
            finalScore: finalScore,
            additionalProperties: AnagramsGameAdditionalProperties(
                gameDuration: 60.0,
                longestWord: longestWordLength,
                totalWordsInSet: totalWordsInSet,
                wordsCompleted: wordsCompleted,
                wordsetId: dailyWordset?.id ?? ""
            )
        )
        print("Anagrams High Score extras: \(longestWordLength), and \(totalWordsInSet)")
        
        scoreManager.saveScore(newScore)
        lastScore = newScore  // save locally for display
        
        // Mark wordset as completed if applicable
        if let wordset = dailyWordset {
            wordsetManager.markWordsetCompleted(wordset, score: finalScore)
        }
        
        print("Score saved successfully: \(finalScore)/\(totalWordsInSet) words completed")
    }

    // MARK: - Gameplay helpers

    func newQuestion() {
        print("🎲 newQuestion() called")
        print("   - currentWordIndex: \(currentWordIndex)")
        print("   - dailyWordset exists: \(dailyWordset != nil)")
        print("   - dailyWordset word count: \(dailyWordset?.words.count ?? 0)")
        
        if let wordset = dailyWordset {
            print("   - wordset.words: \(wordset.words)")
            print("   - about to get word at index \(currentWordIndex)")
        }
        
        guard let wordset = dailyWordset,
              currentWordIndex < wordset.words.count else {
            print("❌ newQuestion() guard failed - completing wordset")
            completeWordset()
            return
        }
        
        currentWord = wordset.words[currentWordIndex]
        print("✅ newQuestion() set currentWord to: '\(currentWord)' from wordset at index \(currentWordIndex)")
        
        scrambledLetters = currentWord.map { String($0) }.shuffled()
        print("🔀 scrambledLetters: \(scrambledLetters)")
        
        // Ensure scrambled letters are actually scrambled
        while scrambledLetters.joined() == currentWord && currentWord.count > 1 {
            scrambledLetters.shuffle()
        }
        print("🔀 Final scrambledLetters: \(scrambledLetters)")
        print("🔀 scrambledLetters.count: \(scrambledLetters.count)")
        
        userAnswer = ""
        usedLetterIndices = []
        currentLetterIndex = 0
        statusText = "Unscramble the letters! (\(wordsCompleted + 1)/\(totalWordsInSet))"
        print("✅ newQuestion() completed - statusText: '\(statusText)'")
    }
    
    private func completeWordset() {
        isWordsetCompleted = true
        endGame()
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
        
        // Find the corresponding scrambled letter index and remove from used indices
        if let scrambledIndex = scrambledLetters.firstIndex(where: { scrambledLetter in
            scrambledLetter == letter && usedLetterIndices.contains(scrambledLetters.firstIndex(of: scrambledLetter) ?? -1)
        }) {
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
            wordsCompleted += 1
            attempts += 1
            currentWordIndex += 1
            statusText = "Correct! (\(wordsCompleted)/\(totalWordsInSet))"
            
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
    
    private func getLongestWordCompleted() -> Int {
        guard let wordset = dailyWordset else { return 0 }
        
        let completedWords = Array(wordset.words.prefix(wordsCompleted))
        return completedWords.map { $0.count }.max() ?? 0
    }

    // MARK: - Private

    private func startMainGame() {
        print("🎮 startMainGame() called")
        
        // Update properties directly since we're already on main thread
        self.gameTimeRemaining = 60
        self.isGameActive = true
        self.statusText = "Go! (\(self.wordsCompleted + 1)/\(self.totalWordsInSet))"
        self.roundStart = Date()
        print("✅ Game is now active - isGameActive: \(self.isGameActive)")
        print("📊 Game state: timeRemaining=\(self.gameTimeRemaining), statusText='\(self.statusText)'")

        // Create timer on main thread
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self = self else { return }
            if self.isGamePaused { return }
            
            // Timer created on main thread, so callback is on main thread
            if self.gameTimeRemaining > 0 {
                self.gameTimeRemaining -= 1
                if self.gameTimeRemaining % 10 == 0 {
                    print("⏱️ Game timer: \(self.gameTimeRemaining)s remaining")
                }
            } else {
                t.invalidate()
                self.endGame()
            }
        }
        print("🎮 startMainGame() completed")
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

// MARK: - Extended Additional Properties for Anagrams (renamed to avoid conflicts)

struct AnagramsGameAdditionalProperties: Codable {
    let gameDuration: Double
    let longestWord: Int
    let totalWordsInSet: Int
    let wordsCompleted: Int
    let wordsetId: String
}

// MARK: - Historical Game Access

extension AnagramsGame {
    func getAvailableWordsetDates() -> [Date] {
        let dateRange = wordsetManager.getAvailableDateRange()
        let calendar = Calendar.current
        
        var dates: [Date] = []
        var currentDate = dateRange.lowerBound
        
        while currentDate <= dateRange.upperBound {
            if wordsetManager.getWordset(for: currentDate) != nil {
                dates.append(currentDate)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return dates
    }
    
    func getWordsetForDate(_ date: Date) -> DailyWordset? {
        return wordsetManager.getWordset(for: date)
    }
    
    func hasPlayedWordset(_ wordset: DailyWordset) -> Bool {
        return wordset.isCompleted
    }
    
    func getWordsetCompletionStatus(_ wordset: DailyWordset) -> (completed: Bool, playedAt: Date?) {
        return (wordset.isCompleted, wordset.completedAt)
    }
}

// MARK: - Wordset Progress Tracking

extension AnagramsGame {
    var todaysWordsetStatus: (hasPlayed: Bool, score: Int) {
        guard let todaysWordset = wordsetManager.getTodaysWordset() else {
            return (false, 0)
        }
        return (todaysWordset.isCompleted, 0) //may need to fix this in the future to not send a hardcoded score of 0
    }
    
    var isWordsetGenerating: Bool {
        return wordsetManager.isGeneratingWordsets
    }
    
    var wordsetGenerationProgress: Double {
        return wordsetManager.generationProgress
    }
}
