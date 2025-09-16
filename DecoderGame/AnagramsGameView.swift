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
    Race against the clock in order to unscramble the most words!
    
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
    
    // MARK: - Game Board
    @ViewBuilder
    private var gameBoard: some View {
        ZStack {
            Color.black.ignoresSafeArea()
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding([.leading, .trailing, .bottom], 20)
        }
    }
    
    // MARK: - Game Area
    @ViewBuilder
    private var gameArea: some View {
        VStack(spacing: 10) {
            if game.isGameActive {
                HStack {
                    Text("Solved: \(game.attempts)")
                        .font(.custom("LuloOne-Bold", size: 14))
                        .foregroundColor(.white)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                    
                    Spacer()
                    
                    if let wordset = wordsetManager.currentWordset {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Word \(game.currentWordIndex + 1) of \(wordset.words.count)")
                                .font(.custom("LuloOne", size: 12))
                                .foregroundColor(.white)
                                .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                .lineLimit(1)
                                .allowsTightening(true)
                            
                            if !game.skippedWordIndices.isEmpty {
                                Text("Skipped: \(game.skippedWordIndices.count)")
                                    .font(.custom("LuloOne", size: 10))
                                    .foregroundColor(.orange)
                                    .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                    .lineLimit(1)
                                    .allowsTightening(true)
                            } else {
                                Text("Skipped: 0")
                                    .font(.custom("LuloOne", size: 10))
                                    .foregroundColor(.white.opacity(0.3))
                                    .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                    .lineLimit(1)
                                    .allowsTightening(true)
                            }
                        }
                    }
                }
                Divider().background(Color.myAccentColor1).padding(5)
            }
            
            Spacer().frame(height: 20)
            
            // User Answer Boxes
            VStack(spacing: 10) {
                Text("Your Answer:")
                    .font(.custom("LuloOne", size: 14))
                    .foregroundColor(.white)
                
                HStack(spacing: 5) {
                    ForEach(0..<game.userAnswer.count, id: \.self) { index in
                        let letter = String(
                            game.userAnswer[game.userAnswer.index(game.userAnswer.startIndex, offsetBy: index)]
                        )
                        letterButton(letter, isScrambled: false, isUsed: false, flashColor: answerFlashColor) {
                            game.removeLetter(at: index)
                        }
                    }
                    
                    // Show empty boxes for remaining letters
                    ForEach(game.userAnswer.count..<game.currentWord.count, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .cornerRadius(0)
                    }
                }
                .frame(minHeight: 55)
                
                HStack(spacing: 25) {
                    // Skip button
                    Button("skip") {
                        game.skipCurrentWord()
                    }
                    .font(.custom("LuloOne", size: 12))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.mySunColor.opacity(0.7))
                    .cornerRadius(8)
                    .disabled(game.isGamePaused || wordsetManager.isGeneratingWordsets)
                    
                    // Clear button
                    Button("clear") {
                        game.clearAnswer()
                    }
                    .font(.custom("LuloOne", size: 12))
                    .foregroundColor(game.userAnswer.isEmpty ? .gray : .white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(game.userAnswer.isEmpty ? Color.gray.opacity(0.3) : Color.pink.opacity(0.7))
                    .cornerRadius(8)
                    .disabled(game.userAnswer.isEmpty || game.isGamePaused || wordsetManager.isGeneratingWordsets)
                }
            }
            
            Spacer().frame(height: 25)
            
            // Scrambled letters grid
            VStack(spacing: 10) {
                Text("Scrambled Letters:")
                    .font(.custom("LuloOne", size: 14))
                    .foregroundColor(.white)
                
                scrambledLettersGrid
            }
        }
        .padding(.horizontal, 10)
    }
    
    // MARK: - Scrambled Letters Grid
    @ViewBuilder
    private var scrambledLettersGrid: some View {
        let num_letters = game.scrambledLetters.count
        let col_count = num_letters < 5 ? 4 : 3
        
        let columns = Array(repeating: GridItem(.flexible(minimum: 50), spacing: 10), count: col_count)
        
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(0..<num_letters, id: \.self) { index in
                letterButton(
                    game.scrambledLetters[index],
                    isScrambled: true,
                    isUsed: game.usedLetterIndices.contains(index)
                ) {
                    game.selectLetter(at: index)
                }
            }
        }
        .padding(.horizontal, 10)
    }
    
    // MARK: - Letter Button
    private func letterButton(
        _ letter: String,
        isScrambled: Bool,
        isUsed: Bool,
        flashColor: Color? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(isUsed ? "" : letter)
                .font(.custom("LuloOne-Bold", size: 20))
                .foregroundColor(.black)
                .frame(width: isScrambled ? 60 : 40, height: isScrambled ? 60 : 40)
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
                            Circle().stroke(Color.myAccentColor2, lineWidth: 3)
                        } else {
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.clear, lineWidth: 1)
                        }
                    }
                )
                //.shadow(radius: isUsed ? 1 : 2)
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
