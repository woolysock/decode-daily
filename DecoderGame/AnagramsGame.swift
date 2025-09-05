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
    @Published var solvedWordIndices: Set<Int> = []
    
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
    @Published var skippedWords: Int = 0
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
    private var isEndingGame: Bool = false
    
    //skipped words tracking
    @Published var skippedWordIndices: Set<Int> = []  // Track which words were skipped
    @Published var allWordsCompleted: Bool = false   // Track if all words in set are done
    
    
    let gameInfo = GameInfo(
        id: "anagrams",
        displayName: "'Grams",
        description: "rearrange letters into words",
        isAvailable: true,
        //gameLocation: AnyView(EmptyView()), // replace with real view if needed
        gameIcon: Image(systemName: "60.arrow.trianglehead.clockwise")
    )
    
    // Initialize with score manager and use singleton wordset manager
    init(scoreManager: GameScoreManager, targetDate: Date? = nil) {
        self.scoreManager = GameScoreManager.shared
        self.wordsetManager = DailyWordsetManager.shared
        self.targetDate = targetDate
        
        print("✅ AnagramsGame initialized with scoreManager: \(type(of: scoreManager))")
        
        // Modified observer - only update if not ending game
        wordsetManager.$currentWordset
            .receive(on: DispatchQueue.main)
            .sink { [weak self] wordset in
                guard let self = self else { return }
                
                // Don't update dailyWordset if we're in the middle of ending the game
                if !self.isEndingGame {
                    self.dailyWordset = wordset
                    print("📝 Updated dailyWordset from wordsetManager (not ending game)")
                } else {
                    print("🚫 Ignored wordsetManager update - game is ending")
                }
            }
            .store(in: &cancellables)
    }
    
    func startGame() {
           print("🚀 AnagramsGame.startGame() called")
           isEndingGame = false  // Reset flag when starting new game
           
           let gameDate = targetDate ?? Date()
           
           guard let todaysWordset = wordsetManager.getTodaysWordset(for: gameDate) else {
               print("❌ startGame(): No wordset available")
               statusText = "No wordset available for this day!"
               return
           }
           
           print("📜 loaded todaysWordset: \(todaysWordset)")
           
           // Sort words for gameplay
           let sortedWords = todaysWordset.words.sorted { $0.count < $1.count }
           
           // Create gameplay wordset
           let gameplayWordset = DailyWordset(date: todaysWordset.date, words: sortedWords)
           dailyWordset = gameplayWordset
           totalWordsInSet = sortedWords.count
           
           // Reset game state
           stopAllTimers()
           gameOver = 0
           isWordsetCompleted = false
           isGamePaused = false
           userAnswer = ""
           usedLetterIndices = []
           roundStart = nil
           lastScore = nil
           
           // Reset progress tracking
           resetProgressTracking()
           
           // Load first question
           loadNextWord()
           
           // Start countdown
           startPreCountdown()
       }
    
    
    // 5. Reset state for current word only
    private func resetCurrentWordState() {
        userAnswer = ""
        usedLetterIndices = []
        currentLetterIndex = 0
        statusText = "Tap the letters\nto unscramble the word"
    }
    
    // 6. Fixed newQuestion() - should just load next word, not reset game
    func newQuestion() {
        print("🎲 newQuestion() called - loading next word")
        loadNextWord()
    }
    
    // 2. New method to reset progress tracking
    private func resetProgressTracking() {
        attempts = 0
        wordsCompleted = 0
        currentWordIndex = 0
        skippedWords = 0
        completedWordLengths = []
        skippedWordIndices = []
        solvedWordIndices = []  // ✅ Reset solved indices
        allWordsCompleted = false
    }
    
    // 3. Separate method for loading words (doesn't reset progress)
    private func loadNextWord() {
        guard let wordset = dailyWordset,
              currentWordIndex < wordset.words.count else {
            print("❌ loadNextWord() - no more words, completing wordset")
            completeWordset()
            return
        }
        
        currentWord = wordset.words[currentWordIndex]
        print("✅ Loading word at index \(currentWordIndex): '\(currentWord)'")
        
        scrambleCurrentWord()
        resetCurrentWordState()
    }
    
    // 4. Separate method for scrambling letters
    private func scrambleCurrentWord() {
        scrambledLetters = currentWord.map { String($0) }.shuffled()
        
        // Ensure actually scrambled for words > 1 letter
        var attempts = 0
        while scrambledLetters.joined() == currentWord && currentWord.count > 1 && attempts < 10 {
            scrambledLetters.shuffle()
            attempts += 1
        }
    }
    
    
    
    private func calculateDifficultyScore() -> Double {
        guard totalWordsInSet > 0 else { return 0.0 }
        
        // Base completion rate (0.0 to 1.0) - based on solved words only
        let completionRate = Double(wordsCompleted) / Double(totalWordsInSet)
        
        // Word difficulty bonus based on lengths of completed words
        let averageWordLength = completedWordLengths.isEmpty ?
            0.0 : Double(completedWordLengths.reduce(0, +)) / Double(completedWordLengths.count)
        
        // Length difficulty multiplier (3-letter words = 1.0x, 8-letter words = 2.0x)
        let lengthMultiplier = max(1.0, (averageWordLength - 2.0) / 4.0)
        
        // Skip penalty calculation
        let skipPenalty = calculateSkipPenalty()
        
        // Base score before penalty
        let baseScore = completionRate * lengthMultiplier * 100.0
        
        // Apply skip penalty (subtract from base score)
        let finalScore = max(0.0, baseScore - skipPenalty)
        
        print("""
        📊 SCORING BREAKDOWN:
        - completionRate: \(String(format: "%.1f%%", completionRate * 100))
        - averageWordLength: \(String(format: "%.1f", averageWordLength))
        - lengthMultiplier: \(String(format: "%.2fx", lengthMultiplier))
        - baseScore: \(String(format: "%.1f", baseScore))
        - skipPenalty: \(String(format: "%.1f", skipPenalty))
        - finalScore: \(String(format: "%.1f", finalScore))
        """)
        
        return finalScore
    }

    private func calculateSkipPenalty() -> Double {
        guard skippedWords > 0 else { return 0.0 }
        
        // Option 1: Fixed penalty per skip (recommended)
        let penaltyPerSkip = 5.0  // Adjust this value as needed
        let fixedPenalty = Double(skippedWords) * penaltyPerSkip
        
        // Option 2: Percentage-based penalty (alternative)
        // let percentagePenalty = Double(skippedWords) / Double(totalWordsInSet) * 20.0  // 20 points max penalty
        
        // Option 3: Escalating penalty (gets worse with more skips)
        // let escalatingPenalty = Double(skippedWords * skippedWords) * 2.0  // 2, 8, 18, 32 points...
        
        return fixedPenalty
    }
    
    func pauseGame() {
        guard !isGamePaused else { return }
        isGamePaused = true
    }
    
    func resumeGame() {
        guard isGamePaused else { return }
        isGamePaused = false
    }
    
    func resetGame() {
        skippedWordIndices.removeAll()
        allWordsCompleted = false
        startGame()
    }
    
    // Problem 3: Enhanced endGame with verification
    func endGame() {
        print("🏁 endGame() called - setting isEndingGame = true")
        isEndingGame = true
        
        verifyGameData()
        
        stopAllTimers()
        isGameActive = false
        isPreCountdownActive = false
        isGamePaused = false
        gameOver = 1

        let gameWon = wordsCompleted >= (totalWordsInSet / 2)
        let difficultyScore = calculateDifficultyScore()
        let finalScore = Int(difficultyScore)
        let longestWord = getLongestWordCompleted()

        if skippedWords > 0 {
            statusText = gameWon ?
                "Well done!\n(\(skippedWords) word\(skippedWords == 1 ? "" : "s") skipped)" :
                "Game over!\n(\(skippedWords) word\(skippedWords == 1 ? "" : "s") skipped)"
        } else {
            statusText = gameWon ? "Perfect! No skips!" : "Game over!"
        }

        scrambledLetters = []
        usedLetterIndices = []
        userAnswer = ""

        let scoreDate = dailyWordset?.date ?? Date()
        
        // Create AnagramsAdditionalProperties
        let anagramsProps = AnagramsAdditionalProperties(
            gameDuration: 60.0,
            longestWord: longestWord,
            totalWordsInSet: totalWordsInSet,
            wordsCompleted: wordsCompleted,
            wordsetId: dailyWordset?.id ?? "",
            completedWordLengths: completedWordLengths,
            difficultyScore: difficultyScore,
            skippedWords: skippedWords
        )
        
        // Create GameScore with the generic initializer that includes additionalProperties
        let newScore = GameScore(
            gameId: gameInfo.id,
            date: scoreDate,
            archiveDate: nil,
            attempts: wordsCompleted,
            timeElapsed: 60.0,
            won: gameWon,
            finalScore: finalScore,
            additionalProperties: anagramsProps  // This will be encoded as Data
        )

        scoreManager.saveScore(newScore)
        lastScore = newScore

        print("""
        ✅ Score saved with current game state:
           - finalScore: \(finalScore)
           - longestWord: \(longestWord)
           - wordsCompleted: \(wordsCompleted)
           - skippedWords: \(skippedWords)
           - difficultyScore: \(difficultyScore)
        """)

        if let wordset = dailyWordset {
            wordsetManager.markWordsetCompleted(wordset, score: finalScore)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isEndingGame = false
        }
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
    
    // 7. Fixed checkAnswer() to properly track progress
    private func checkAnswer() {
        let isCorrect = userAnswer.uppercased() == currentWord.uppercased()
        
        if isCorrect {
            print("✅ Correct answer for word \(currentWordIndex): '\(currentWord)'")
            
            // Track completion by actual index
            solvedWordIndices.insert(currentWordIndex)  // ✅ Track by index
            wordsCompleted += 1  // Still increment for scoring
            attempts += 1
            completedWordLengths.append(currentWord.count)
            
            // Remove from skipped if it was previously skipped
            skippedWordIndices.remove(currentWordIndex)
            
            statusText = "Correct!\n"
            
            // Move to next unsolved word
            if let nextIndex = findNextUnsolvedWordIndex() {
                currentWordIndex = nextIndex
                print("📍 Moving to next word at index: \(nextIndex)")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.loadNextWord()
                }
            } else {
                print("🎉 All words completed!")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.allWordsCompleted = true
                    self.endGame()
                }
            }
            
        } else {
            print("❌ Wrong answer: '\(userAnswer)' vs '\(currentWord)'")
            statusText = "Wrong!\nTry again."
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.resetCurrentWordState()
            }
        }
    }
    
    
    
    private func getLongestWordCompleted() -> Int {
        guard !completedWordLengths.isEmpty else {
            print("⚠️ No completed word lengths found")
            return 0
        }
        
        let longestLength = completedWordLengths.max() ?? 0
        print("📏 Longest word completed: \(longestLength) letters from lengths: \(completedWordLengths)")
        return longestLength
    }
    
    func verifyGameData() {
        print("""
        🔍 GAME DATA VERIFICATION:
        - wordsCompleted: \(wordsCompleted)
        - skippedWords: \(skippedWords) 
        - completedWordLengths count: \(completedWordLengths.count)
        - completedWordLengths: \(completedWordLengths)
        - solvedWordIndices: \(solvedWordIndices)
        - skippedWordIndices: \(skippedWordIndices)
        - totalWordsInSet: \(totalWordsInSet)
        - longestWordCompleted: \(getLongestWordCompleted())
        """)
        
        // Verify consistency
        if completedWordLengths.count != wordsCompleted {
            print("⚠️ WARNING: completedWordLengths.count (\(completedWordLengths.count)) != wordsCompleted (\(wordsCompleted))")
        }
        
        if solvedWordIndices.count != wordsCompleted {
            print("⚠️ WARNING: solvedWordIndices.count (\(solvedWordIndices.count)) != wordsCompleted (\(wordsCompleted))")
        }
        
        if skippedWordIndices.count != skippedWords {
            print("⚠️ WARNING: skippedWordIndices.count (\(skippedWordIndices.count)) != skippedWords (\(skippedWords))")
        }
    }
    
    
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
    
    func debugEndGameOverlayData() {
        print("🎮 DEBUGGING ENDGAME OVERLAY DATA ACCESS:")
        
        // Check what lastScore contains
        if let score = lastScore {
            print("✅ lastScore exists:")
            print("   - finalScore: \(score.finalScore)")
            print("   - attempts: \(score.attempts)")
            print("   - won: \(score.won)")
            print("   - gameId: \(score.gameId)")
            
            // Check anagramsProperties using the computed property
            if let anagramsProps = score.anagramsProperties {
                print("✅ AnagramsAdditionalProperties found:")
                print("   - wordsCompleted: \(anagramsProps.wordsCompleted)")
                print("   - skippedWords: \(anagramsProps.skippedWords)")
                print("   - longestWord: \(anagramsProps.longestWord)")
                print("   - totalWordsInSet: \(anagramsProps.totalWordsInSet)")
                print("   - completedWordLengths: \(anagramsProps.completedWordLengths)")
                print("   - difficultyScore: \(anagramsProps.difficultyScore)")
            } else {
                print("❌ Could not decode anagramsProperties")
                print("   - additionalPropertiesData exists: \(score.additionalPropertiesData != nil)")
                if let data = score.additionalPropertiesData {
                    print("   - data size: \(data.count) bytes")
                }
            }
        } else {
            print("❌ lastScore is nil")
        }
        
        // Check current game state (in case overlay is reading from game directly)
        print("🎯 CURRENT GAME STATE:")
        print("   - wordsCompleted: \(wordsCompleted)")
        print("   - skippedWords: \(skippedWords)")
        print("   - getLongestWordCompleted(): \(getLongestWordCompleted())")
        print("   - totalWordsInSet: \(totalWordsInSet)")
        print("   - completedWordLengths: \(completedWordLengths)")
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
    
    // 8. Fixed skipCurrentWord to use consistent logic
    func skipCurrentWord() {
        guard let wordset = dailyWordset else { return }
        
        print("⏭️ Skipping word at index \(currentWordIndex): '\(currentWord)'")
        
        // Mark as skipped
        skippedWordIndices.insert(currentWordIndex)
        skippedWords += 1
        
        // Find next word
        if let nextIndex = findNextUnsolvedWordIndex() {
            currentWordIndex = nextIndex
            statusText = "Word skipped!\nNew word:"
            
            print("📍 After skip, moving to index: \(nextIndex)")
            loadNextWord()
        } else {
            print("🏁 No more words after skip - ending game")
            allWordsCompleted = true
            endGame()
        }
    }
    
    // 9. Improved findNextUnsolvedWordIndex with better logic
    
    private func findNextUnsolvedWordIndex() -> Int? {
        guard let wordset = dailyWordset else { return nil }
        
        let totalWords = wordset.words.count
        
        print("🔍 Finding next word: solved=\(solvedWordIndices), skipped=\(skippedWordIndices)")
        
        // Strategy 1: Find first unvisited word (not solved, not skipped)
        for i in 0..<totalWords {
            if !solvedWordIndices.contains(i) && !skippedWordIndices.contains(i) {
                print("📍 Found unvisited word at index: \(i)")
                return i
            }
        }
        
        // Strategy 2: Revisit skipped words that haven't been solved
        for i in skippedWordIndices.sorted() {
            if !solvedWordIndices.contains(i) {
                print("📍 Revisiting skipped word at index: \(i)")
                return i
            }
        }
        
        print("📍 No more words available")
        return nil
    }
    
    
    // 10. Add method to start pre-countdown separately
    private func startPreCountdown() {
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
    }
    
    // 11. Add debug method to check state
    func debugGameState() {
        print("""
            🐛 GAME STATE DEBUG:
            - currentWordIndex: \(currentWordIndex)
            - wordsCompleted: \(wordsCompleted)
            - totalWordsInSet: \(totalWordsInSet)
            - skippedWords: \(skippedWords)
            - solvedWordIndices: \(solvedWordIndices)
            - skippedWordIndices: \(skippedWordIndices)
            - allWordsCompleted: \(allWordsCompleted)
            - currentWord: '\(currentWord)'
            - isGameActive: \(isGameActive)
            """)
    }
    
}





