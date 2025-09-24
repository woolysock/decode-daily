//
//  AnagramsGameView.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/12/25.
//

import SwiftUI
import Combine
import Mixpanel

struct AnagramsGameView: View {
    let targetDate: Date?
    
    @Environment(\.sizeCategory) var sizeCategory
    @ObservedObject private var wordsetManager = DailyWordsetManager.shared
    @EnvironmentObject var scoreManager: GameScoreManager
    @Environment(\.dismiss) private var dismiss

    @StateObject private var game: AnagramsGame
    @StateObject private var dailyCheckManager = DailyCheckManager.shared
    @State private var navigateToSpecificLeaderboard = false

    @State private var showHowToPlay = false
    @State private var showEndGameOverlay = false
    @State private var hasStartedRound = false
    @State private var answerFlashColor: Color? = nil
    
    private let instructionsText = """
    Race against the clock to unscramble the most words!
    
    Tap letters to spell out the correct word in the boxes above.
    
    O  R  W  D    →    W  O  R  D 

    If you make a mistake, tap "clear" to remove the letters and try again. 
    
    If you're stumped, "skip" a word and try it later!
    
    You get 1 minute! ⏳
    
    """
    
    init(targetDate: Date? = nil) {
        self.targetDate = targetDate
        self._game = StateObject(wrappedValue: AnagramsGame(scoreManager: GameScoreManager.shared, targetDate: targetDate))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ZStack {
                    Color.black.ignoresSafeArea()
                    gameContent
                }
                .onAppear {
                    initializeGame()
                    
                    // MIXPANEL ANALYTICS CAPTURE
                    Mixpanel.mainInstance().track(event: "Anagrams Game Page View", properties: [
                        "app": "Decode! Daily iOS",
                        "build_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"],
                        "date": Date().formatted(),
                        "subscription_tier": SubscriptionManager.shared.currentTier.displayName
                    ])
                    print("📈 🪵 MIXPANEL DATA LOG EVENT: Anagrams Game Page View")
                    print("📈 🪵 date: \(Date().formatted())")
                    print("📈 🪵 sub tier: \(SubscriptionManager.shared.currentTier.displayName)")
                }
                
                // Overlays at root level
                if showEndGameOverlay {
                    EndGameOverlay(
                        gameID: game.gameInfo.id,
                        finalScore: game.lastScore?.finalScore ?? game.attempts,
                        displayName: game.gameInfo.displayName,
                        isVisible: $showEndGameOverlay,
                        onPlayAgain: { startNewGame() },
                        onHighScores: {
                            navigateToSpecificLeaderboard = true
                            dismiss()
                        },
                        onMenu: {
                            showEndGameOverlay = false
                            dismiss()
                        },
                        gameScore: game.lastScore
                    )
                    .transition(.opacity)
                }
                
                if showHowToPlay {
                    GeometryReader { geometry in
                        HowToPlayOverlay(
                            gameID: game.gameInfo.id,
                            instructions: instructionsText,
                            isVisible: $showHowToPlay
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    }
                    .ignoresSafeArea(.all)
                    .transition(.opacity)
                }
            }
            .onChange(of: dailyCheckManager.showNewDayOverlay) { oldValue, newValue in
                // Only respond to new day overlay if this is NOT an archived game
                if targetDate == nil {
                    if newValue {
                        print("AnagramsGameView: Force ending game due to new day overlay")
                        game.endGame()
                        showEndGameOverlay = false
                        showHowToPlay = false
                        hasStartedRound = false
                    } else if oldValue == true && newValue == false {
                        print("AnagramsGameView: New day overlay dismissed, returning to main menu")
                        dismiss()
                    }
                }
            }
            .onAppear {
                if game.gameOver > 0 {
                    game.resetGame()
                }
            }
        }
        .navigationDestination(isPresented: $navigateToSpecificLeaderboard) {
            MultiGameLeaderboardView(selectedGameID: game.gameInfo.id)
        }
        .navigationBarBackButtonHidden(showEndGameOverlay || showHowToPlay)
        
    }
    
    // MARK: - Main Game Content
    @ViewBuilder
    private var gameContent: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 10)
            
            // Header
            headerSection
            
            Spacer().frame(height: 5)
            Divider().background(.white).padding(5)
            Spacer().frame(height: 15)
            
            // Status and icons
            statusSection
            
            // Game board
            gameBoard
            
            Spacer()
        }
        .onChange(of: wordsetManager.currentWordset) { oldValue, newValue in
            print("📝 wordsetManager.currentWordset changed:")
            print("   - New wordset: \(newValue?.words.count ?? 0) words")
            print("   - hasStartedRound: \(hasStartedRound)")
            
            if !hasStartedRound && newValue != nil && !wordsetManager.isGeneratingWordsets && !showHowToPlay {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    tryToStartGame()
                }
            }
        }
        .onChange(of: wordsetManager.isGeneratingWordsets) { oldValue, newValue in
            print("📝 isGeneratingWordsets changed: \(oldValue) → \(newValue)")
            
            if oldValue == true && newValue == false &&
               !hasStartedRound &&
               wordsetManager.currentWordset != nil &&
               !showHowToPlay {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    tryToStartGame()
                }
            }
        }
        .onChange(of: showHowToPlay, initial: false) { oldValue, newValue in
            if newValue {
                game.pauseGame()
            } else {
                game.resumeGame()
                
                if !hasStartedRound &&
                   wordsetManager.currentWordset != nil &&
                   !wordsetManager.isGeneratingWordsets {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        tryToStartGame()
                    }
                }
            }
        }
        .onChange(of: game.gameOver, initial: false) { oldValue, newValue in
            if newValue == 1 {
                showEndGameOverlay = true
            }
        }
        .onChange(of: game.statusText) { oldValue, newValue in
            if newValue.contains("Correct") {
                flashAnswer(correct: true)
            } else if newValue.contains("Wrong") {
                flashAnswer(correct: false)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("Wrong answer detected")
                    game.usedLetterIndices.removeAll()
                    game.userAnswer = ""
                }
            }
        }
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
        HStack {
            Spacer().frame(width: 5)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(game.gameInfo.displayName)
                        .foregroundColor(.white)
                        .font(.custom("LuloOne-Bold", size: 20))
                        .lineLimit(1)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .allowsTightening(true)
                        .onTapGesture { tryToStartGame() }
                    
                    // Archive indicator
                    if targetDate != nil {
                        Text("ARCHIVE")
                            .font(.custom("LuloOne", size: 8))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                            .lineLimit(1)
                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                            .allowsTightening(true)
                    }
                }
                
                // Daily indicator
                if let targetDate = targetDate {
                    Text(DateFormatter.dayStringFormatter.string(from: targetDate.localStartOfDay))
                        .font(.custom("LuloOne", size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .allowsTightening(true)
                } else if let wordset = wordsetManager.currentWordset {
                    Text(DateFormatter.dayStringFormatter.string(from: wordset.date))
                        .font(.custom("LuloOne", size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .allowsTightening(true)
                }
            }

            Spacer()

            // Timer
            Group {
                if game.isGameActive {
                    Text("\(game.gameTimeRemaining)")
                        .font(.custom("LuloOne-Bold", size: 20))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .frame(minWidth: 54, alignment: .center)
                        .transition(.opacity)
                        .lineLimit(1)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .allowsTightening(true)
                } else {
                    Text(" ")
                        .font(.custom("LuloOne-Bold", size: 20))
                        .frame(minWidth: 54)
                        .opacity(0)
                        .lineLimit(1)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .allowsTightening(true)
                }
            }

            Spacer()

            Button { showHowToPlay = true } label: {
                Image(systemName: "questionmark.circle")
                    .foregroundColor(.white)
                    .font(.title2)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Status Section
    @ViewBuilder
    private var statusSection: some View {
        VStack(spacing: 5) {
            if wordsetManager.isGeneratingWordsets {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    Text("Loading today's words...")
                        .foregroundColor(.white)
                        .font(.custom("LuloOne", size: 12))
                        .lineLimit(3)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .allowsTightening(true)
                }
            } else {
                Text(game.statusText)
                    .foregroundColor(.white)
                    .font(.custom("LuloOne", size: 12))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)
                    .lineLimit(2)
                    .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                    .allowsTightening(true)
            }

            if game.statusText.contains("Wrong") {
                Image(systemName: "wrongwaysign.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.red)
            } else if game.statusText.contains("Correct") {
                Image(systemName: "checkmark.seal.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(Color.myAccentColor1)
            } else if game.statusText.contains("Tap") {
                Image(systemName: "hand.tap.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(wordsetManager.isGeneratingWordsets ? .gray : .white)
            } else {
                Image(systemName: "hare.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.clear)
            }
        }
    }
    
    @ViewBuilder
    private var gameBoard: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Main game content
                VStack(spacing: 30) {
                    if game.isPreCountdownActive {
                        Text("\(game.countdownValue)")
                            .font(.custom("LuloOne-Bold", size: 100))
                            .foregroundColor(.white)
                            .monospacedDigit()
                            .scaleEffect(1.05)
                            .transition(.scale)
                            .multilineTextAlignment(.center)
                    } else if game.isGameActive {
                        Spacer().frame(height: 5)
                        gameArea
                        Spacer()
                    } else if wordsetManager.isGeneratingWordsets {
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(2.0)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            
                            Text("Preparing today's challenge...")
                                .font(.custom("LuloOne", size: 16))
                                .foregroundColor(.white)
                        }
                    } else {
                        Spacer()
                    }
                    Spacer()
                }
                .padding([.leading, .trailing], 20)
                
                // Bottom-anchored shuffle button with safe area consideration
                if game.isGameActive {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                game.shuffleCurrentWord()
                            }) {
                                Image(systemName: "shuffle")
                                    .font(.system(size: geometry.size.height < 600 ? 20 : 24, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(
                                        width: geometry.size.height < 600 ? 48 : 56,
                                        height: geometry.size.height < 600 ? 48 : 56
                                    )
                                    .background(Color.myAccentColor2.opacity(0.9))
                                    .cornerRadius(geometry.size.height < 600 ? 24 : 28)
                                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            .disabled(game.isGamePaused || wordsetManager.isGeneratingWordsets)
                            .opacity((game.isGamePaused || wordsetManager.isGeneratingWordsets) ? 0.5 : 1.0)
                            .scaleEffect((game.isGamePaused || wordsetManager.isGeneratingWordsets) ? 0.9 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: game.isGamePaused)
                            Spacer()
                        }
                        .padding(.bottom, max(20, geometry.safeAreaInsets.bottom + 10))
                    }
                }
            }
        }
    }
    
    // MARK: - Game Area
    @ViewBuilder
    private var gameArea: some View {
        GeometryReader { geometry in
            let availableHeight = geometry.size.height
            let isCompactHeight = availableHeight < 400 // Adjusted for iPhone SE (568 points total, less available after headers)
            
            VStack(spacing: isCompactHeight ? 8 : 10) {
                // Game stats section - make more compact on small screens
                if game.isGameActive {
                    HStack {
                        Text("Solved: \(game.attempts)")
                            .font(.custom("LuloOne-Bold", size: isCompactHeight ? 12 : 14))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                            .allowsTightening(true)
                        
                        Spacer()
                        
                        if let wordset = wordsetManager.currentWordset {
                            VStack(alignment: .trailing, spacing: 1) {
                                Text("Word \(game.currentWordIndex + 1) of \(wordset.words.count)")
                                    .font(.custom("LuloOne", size: isCompactHeight ? 10 : 12))
                                    .foregroundColor(.white)
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(1)
                                    .allowsTightening(true)
                                
                                if !game.skippedWordIndices.isEmpty {
                                    Text("Skipped: \(game.skippedWordIndices.count)")
                                        .font(.custom("LuloOne", size: isCompactHeight ? 8 : 10))
                                        .foregroundColor(.orange)
                                        .minimumScaleFactor(0.7)
                                        .lineLimit(1)
                                        .allowsTightening(true)
                                } else {
                                    Text("Skipped: 0")
                                        .font(.custom("LuloOne", size: isCompactHeight ? 8 : 10))
                                        .foregroundColor(.white.opacity(0.3))
                                        .minimumScaleFactor(0.7)
                                        .lineLimit(1)
                                        .allowsTightening(true)
                                }
                            }
                        }
                    }
                    Divider().background(Color.myAccentColor1).padding(2)
                }
                
                // Answer section - make more compact
                VStack(spacing: 8) {
                    Text("Your Answer:")
                        .font(.custom("LuloOne", size: isCompactHeight ? 12 : 14))
                        .foregroundColor(.white)
                    
                    HStack(spacing: isCompactHeight ? 3 : 4) {
                        ForEach(0..<game.userAnswer.count, id: \.self) { index in
                            let letter = String(
                                game.userAnswer[game.userAnswer.index(game.userAnswer.startIndex, offsetBy: index)]
                            )
                            letterButton(
                                letter,
                                isScrambled: false,
                                isUsed: false,
                                flashColor: answerFlashColor,
                                isCompact: isCompactHeight
                            ) {
                                game.removeLetter(at: index)
                            }
                        }
                        
                        // Show empty boxes for remaining letters
                        ForEach(game.userAnswer.count..<game.currentWord.count, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(
                                    width: isCompactHeight ? 32 : 40,
                                    height: isCompactHeight ? 32 : 40
                                )
                                .cornerRadius(0)
                        }
                    }
                    .frame(minHeight: isCompactHeight ? 40 : 55)
                    
                    // Action buttons - make more compact
                    HStack(spacing: isCompactHeight ? 15 : 25) {
                        Button("skip") {
                            game.skipCurrentWord()
                        }
                        .font(.custom("LuloOne", size: isCompactHeight ? 10 : 12))
                        .foregroundColor(.white)
                        .padding(.horizontal, isCompactHeight ? 12 : 20)
                        .padding(.vertical, isCompactHeight ? 6 : 8)
                        .background(Color.mySunColor.opacity(0.7))
                        .cornerRadius(6)
                        .disabled(game.isGamePaused || wordsetManager.isGeneratingWordsets)
                        
                        Button("clear") {
                            game.clearAnswer()
                        }
                        .font(.custom("LuloOne", size: isCompactHeight ? 10 : 12))
                        .foregroundColor(game.userAnswer.isEmpty ? .gray : .white)
                        .padding(.horizontal, isCompactHeight ? 12 : 20)
                        .padding(.vertical, isCompactHeight ? 6 : 8)
                        .background(game.userAnswer.isEmpty ? Color.gray.opacity(0.3) : Color.pink.opacity(0.7))
                        .cornerRadius(6)
                        .disabled(game.userAnswer.isEmpty || game.isGamePaused || wordsetManager.isGeneratingWordsets)
                    }
                }
                
                // Spacer that adapts to available space
                Spacer().frame(height: isCompactHeight ? 8 : 15)
                
                // Scrambled letters section - make grid more compact
                VStack(spacing: isCompactHeight ? 5 : 8) {
                    Text("Scrambled Letters:")
                        .font(.custom("LuloOne", size: isCompactHeight ? 12 : 14))
                        .foregroundColor(.white)
                    
                    responsiveScrambledLettersGrid(isCompact: isCompactHeight)
                }
                
                // Reserve space for shuffle button at bottom
                Spacer().frame(height: isCompactHeight ? 65 : 80)
                
//                Text("📏 isCompactHeight? \(isCompactHeight)\navailableHeight: \(availableHeight)")
//                    .font(.custom("LuloOne", size: isCompactHeight ? 12 : 14))
//                    .foregroundColor(.white)
            }
            .padding(.horizontal, isCompactHeight ? 8 : 10)
        }
    }
    
    // MARK: - Scrambled Letters Grid
    @ViewBuilder
    private func responsiveScrambledLettersGrid(isCompact: Bool) -> some View {
        let num_letters = game.scrambledLetters.count
        let buttonSize: CGFloat = isCompact ? 45 : 60
        let spacing: CGFloat = isCompact ? 6 : 10
        
        // Calculate column count based on number of letters and screen size
        let col_count = calculateColumnCount(letterCount: num_letters, isCompact: isCompact)
        
        let columns = Array(repeating: GridItem(.flexible(minimum: buttonSize, maximum: buttonSize + 10), spacing: spacing), count: col_count)
        
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(0..<num_letters, id: \.self) { index in
                letterButton(
                    game.scrambledLetters[index],
                    isScrambled: true,
                    isUsed: game.usedLetterIndices.contains(index),
                    isCompact: isCompact
                ) {
                    game.selectLetter(at: index)
                }
            }
        }
        .padding(.horizontal, isCompact ? 20 : 30)
    }
    
    // MARK: - Helper Function for Column Count
    private func calculateColumnCount(letterCount: Int, isCompact: Bool) -> Int {
        if isCompact {
            return letterCount <= 4 ? letterCount : (letterCount <= 6 ? 3 : 4)
        } else {
            return letterCount < 5 ? 4 : 3
        }
    }
    
    // MARK: - Updated Letter Button with Compact Mode
    private func letterButton(
        _ letter: String,
        isScrambled: Bool,
        isUsed: Bool,
        flashColor: Color? = nil,
        isCompact: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        let buttonSize: CGFloat = isCompact ? (isScrambled ? 45 : 32) : (isScrambled ? 60 : 40)
        let fontSize: CGFloat = isCompact ? (isScrambled ? 18 : 16) : 20
        
        return Button(action: action) {
            Text(isUsed ? "" : letter)
                .font(.custom("LuloOne-Bold", size: fontSize))
                .foregroundColor(.black)
                .frame(width: buttonSize, height: buttonSize)
                .offset(x: 1, y: 1)
                .multilineTextAlignment(.center)
                .background(
                    (flashColor != nil ? flashColor! :
                        (isUsed ? Color.gray.opacity(0.3) :
                            (isScrambled ? Color.white : Color.myAccentColor1)))
                )
                .clipShape(isScrambled ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 5)))
                .overlay(
                    Group {
                        if isScrambled {
                            Circle().stroke(Color.myAccentColor2, lineWidth: isCompact ? 2 : 3)
                        } else {
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.clear, lineWidth: 1)
                        }
                    }
                )
                .animation(.easeInOut(duration: 0.3), value: flashColor)
        }
        .disabled(!game.isGameActive || game.isGamePaused || isUsed || wordsetManager.isGeneratingWordsets)
    }
    
    // MARK: - Initialization
    private func initializeGame() {
        print("🔧 Initializing game...")
        print("📊 WordsetManager Status: \(wordsetManager.currentWordset?.words.count ?? 0) words")
        
        if UserDefaults.standard.bool(forKey: "hasSeenHowToPlay_anagrams") {
            if wordsetManager.currentWordset != nil && !wordsetManager.isGeneratingWordsets {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    tryToStartGame()
                }
            }
        } else {
            showHowToPlay = true
        }
    }
    
    private func tryToStartGame() {
        print("🚥 AnagramsGameView(): tryToStartGame()...")
        guard !hasStartedRound,
              wordsetManager.currentWordset != nil,
              !wordsetManager.isGeneratingWordsets else {
            print("❌ tryToStartGame(): Cannot start - conditions not met")
            return
        }
        
        hasStartedRound = true
        game.startGame()
    }
    
    // MARK: - Game Control Methods
    private func startNewGame() {
        showEndGameOverlay = false
        hasStartedRound = false
        
        game.resetGame()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            tryToStartGame()
        }
    }
    
    // MARK: - Flash Answer
    private func flashAnswer(correct: Bool) {
        answerFlashColor = correct ? .green : .red
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            answerFlashColor = nil
        }
    }
}

// Helper struct to allow both Circle and RoundedRectangle in clipShape
struct AnyShape: Shape {
    private let _path: @Sendable (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        _path = { rect in
            shape.path(in: rect)
        }
    }

    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}
