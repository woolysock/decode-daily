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
    var scoreManager: GameScoreManager
    let targetDate: Date?
    private let wordsetManager: DailyWordsetManager
    
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
    @Published var completedWordLengths: [Int] = []
    
    
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
        //gameLocation: AnyView(EmptyView()), // replace with real view if needed
        gameIcon: Image(systemName: "60.arrow.trianglehead.clockwise")
    )
    
    // Initialize with score manager and use singleton wordset manager
    init(scoreManager: GameScoreManager, targetDate: Date? = nil) {
        self.scoreManager = GameScoreManager.shared
        self.wordsetManager = DailyWordsetManager.shared  // Use singleton
        self.targetDate = targetDate
        
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
        
        let gameDate = targetDate ?? Date()
        
        print("🎯 TARGET DATE DEBUG:")
        print("   - targetDate: \(String(describing: targetDate))")
        print("   - Current Date(): \(Date())")
        print("   - gameDate (final): \(gameDate)")
        print("   - gameDate formatted: \(DateFormatter.debugFormatter.string(from: gameDate))")
        
        print("🔍 Before calling getTodaysWordset:")
        print("   - wordsetManager.currentWordset date: \(String(describing: wordsetManager.currentWordset?.date))")
        
        guard let todaysWordset = wordsetManager.getTodaysWordset(for: gameDate) else {
            print("startGame(): ❌ No wordset available")
            statusText = "No wordset available for this day!"
            return
        }
        
        print("📜 loaded todaysWordset: \(todaysWordset)")
        
        // Sort words shortest-to-longest
        // Keep the date as a string, since your JSON stores it that way
        let sortedWordset = DailyWordset(
            date: todaysWordset.date,  // ✅ keep as String
            words: todaysWordset.words.sorted { $0.count < $1.count }
        )
        
        dailyWordset = sortedWordset
        totalWordsInSet = sortedWordset.words.count
        
        // Reset game state
        stopAllTimers()
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
        completedWordLengths = []
        
        // Load first question
        newQuestion()
        
        // Pre-countdown setup
        DispatchQueue.main.async {
            self.statusText = "Ready, set. . ."
            self.countdownValue = 3
            self.isPreCountdownActive = true
            self.isGameActive = false
            
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
        
        print("✅ startGame(): completed setup with sorted words")
    }


    
    private func calculateDifficultyScore() -> Double {
        guard totalWordsInSet > 0 else { return 0.0 }
        
        // Base completion rate (0.0 to 1.0)
        let completionRate = Double(wordsCompleted) / Double(totalWordsInSet)
        
        // Word difficulty bonus based on lengths of completed words
        let averageWordLength = completedWordLengths.isEmpty ?
        0.0 : Double(completedWordLengths.reduce(0, +)) / Double(completedWordLengths.count)
        
        // Length difficulty multiplier (3-letter words = 1.0x, 8-letter words = 2.0x)
        let lengthMultiplier = max(1.0, (averageWordLength - 2.0) / 4.0)
        
        // Combine completion rate with difficulty
        // Score ranges from 0 to ~200 (100% completion * 2.0 length multiplier * 100 scale factor)
        let difficultyScore = completionRate * lengthMultiplier * 100.0
        
        return difficultyScore
    }
    
//    func startGameWithWordset(_ wordset: DailyWordset) {
//        print("startGameWithWordset: \(wordset)")
//        dailyWordset = wordset
//        totalWordsInSet = wordset.words.count
//        
//        stopAllTimers()
//        gameOver = 0
//        attempts = 0
//        wordsCompleted = 0
//        currentWordIndex = 0
//        isWordsetCompleted = false
//        isGamePaused = false
//        userAnswer = ""
//        usedLetterIndices = []
//        statusText = "Get ready..."
//        countdownValue = 3
//        isPreCountdownActive = true
//        isGameActive = false
//        roundStart = nil
//        lastScore = nil
//        
//        newQuestion()
//        DispatchQueue.main.async {
//            self.preCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
//                guard let self = self else { return }
//                if self.isGamePaused { return }
//                
//                if self.countdownValue > 1 {
//                    self.countdownValue -= 1
//                } else {
//                    t.invalidate()
//                    self.isPreCountdownActive = false
//                    self.startMainGame()
//                }
//            }
//        }
//    }
    
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

        let gameWon = wordsCompleted >= (totalWordsInSet / 2)
        let difficultyScore = calculateDifficultyScore()
        let finalScore = Int(difficultyScore)

        statusText = gameWon ? "Well done!" : "Game over!"
        scrambledLetters = []
        usedLetterIndices = []
        userAnswer = ""

        // Save score with the wordset date
        let scoreDate = dailyWordset?.date ?? Date()
        let newScore = GameScore(
            gameId: gameInfo.id,
            date: scoreDate,
            attempts: wordsCompleted, // ✅ use wordsCompleted, not attempts
            timeElapsed: 60.0,
            won: gameWon,
            finalScore: finalScore,
            additionalProperties: AnagramsAdditionalProperties(
                gameDuration: 60.0,
                longestWord: getLongestWordCompleted(),
                totalWordsInSet: totalWordsInSet,
                wordsCompleted: wordsCompleted,
                wordsetId: dailyWordset?.id ?? "",
                completedWordLengths: completedWordLengths,
                difficultyScore: difficultyScore
            )
        )

        // Save score and update lastScore immediately
        scoreManager.saveScore(newScore)
        lastScore = newScore

        // Mark wordset as completed
        if let wordset = dailyWordset {
            wordsetManager.markWordsetCompleted(wordset, score: finalScore)
        }

        print("""
        ✅ Score saved:
           - finalScore: \(finalScore)
           - longestWordCompleted: \(getLongestWordCompleted())
           - totalWordsInSet: \(totalWordsInSet)
           - wordsCompleted: \(wordsCompleted)
           - dailyWordsetID: \(dailyWordset?.id ?? "N/A")
           - completedWordLengths: \(completedWordLengths)
           - difficultyScore: \(difficultyScore)
           - scoreDate: \(scoreDate)
        """)
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
        statusText = "Tap the letters\n to unscramble the word"
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
            completedWordLengths.append(currentWord.count)
            
            currentWordIndex += 1
            statusText = "Correct!\n"
            
            if currentWordIndex < totalWordsInSet {
                // Next word
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.newQuestion()
                }
            } else {
                // Wordset completed - finalize game
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isWordsetCompleted = true
                    self.endGame()
                }
            }
            
        } else {
            statusText = "Wrong!\nTry again."
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
        self.statusText = "Tap the letters\n to unscramble the word"
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
    
    var isWordsetGenerating: Bool {
        return wordsetManager.isGeneratingWordsets
    }
    
    var wordsetGenerationProgress: Double {
        return wordsetManager.generationProgress
    }
    
    
}





