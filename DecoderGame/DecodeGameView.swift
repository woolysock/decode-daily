//
//  DecodeGameView.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/14/25.
//

import SwiftUI
import Mixpanel

struct DecodeGameView: View {
    let targetDate: Date?
    
    @StateObject private var game: DecodeGame
    @EnvironmentObject var scoreManager: GameScoreManager
    @Environment(\.dismiss) private var dismiss  // Add this
    
    // Color picker state
    @State private var showingColorPicker = false
    @State private var colorPickerPosition = CGPoint.zero
    @State private var selectedSquare: (row: Int, col: Int) = (0, 0)
    @State private var pickerSize: CGSize = .zero
    @State private var frameOffset: CGPoint = .zero
    
    // Overlay states
    @State private var showHowToPlay = false
    @State private var showEndGameOverlay = false
    @State private var showCodeReveal = false
    @State private var navigateToSpecificLeaderboard = false
    @State private var shouldNavigateToArchive = false
    //let onNavigateToArchive: (() -> Void)?
    
    // Remove navigateToMenu since we'll use dismiss
    @State private var navigateToHighScores = false
    
    // Track if this is the first launch AND if we should animate after how-to-play
    @State private var isFirstLaunch = true
    @State private var shouldAnimateAfterHowToPlay = false
    
    
    // Initialize with proper dependency injection
    init(targetDate: Date? = nil) {
        //print("🔍 TRACE: DecodeGameView init() - targetDate: \(String(describing: targetDate))")
        
        self.targetDate = targetDate
        
        //print("🔍 TRACE: About to create StateObject with closure...")
        self._game = StateObject(wrappedValue: {
            //print("🔍 TRACE: Inside StateObject closure, creating DecodeGame...")
            //print("🔍 TRACE: About to access GameScoreManager.shared")
            let scoreManager = GameScoreManager.shared
            //print("🔍 DecodeGameView(): GameScoreManager.shared: \(type(of: scoreManager))")

            //print("🔍 TRACE: About to call DecodeGame init")
            let game = DecodeGame(scoreManager: scoreManager, targetDate: targetDate)
            
            //self.onNavigateToArchive = onNavigateToArchive
            return game
        }())
        
        //print("🔍 DecodeGameView init completed.")
        
    }
    
    var body: some View {
        
        ZStack {
            Color.black.ignoresSafeArea()
            
            if game.theCode.isEmpty {
                // Loading state - show while game initializes
                VStack {
                    Text("Loading...")
                        .foregroundColor(.white)
                        .font(.custom("LuloOne", size: 20))
                }
            } else {
                // Main game content - only shown when game is properly initialized
                VStack() {
                    Spacer().frame(height: 10)
                    
                    // Title + Timer + Help button
                    HStack {
                        
                        //Game name, Archive Indicator, Date
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                // Game name
                                Text(game.gameInfo.displayName)
                                    .foregroundColor(.white)
                                    .font(.custom("LuloOne-Bold", size: 20))
                                
                                
                                // Archive indicator
                                if targetDate != nil {
                                    Text("ARCHIVE")
                                        .font(.custom("LuloOne", size: 8))
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                            
                            Text(game.displayMode)
                                .font(.custom("LuloOne", size: 12))
                                .foregroundColor(game.willScoreCount ? .gray : .yellow) // Different color for practice mode
                            
                            //REUSE THIS WHEN DAILIES WORK:
                            
                            //                            else if let codeset = codeSetManager.currentCodeSet {
                            //                                // Show the wordset date when in normal mode
                            //                                Text(DateFormatter.dayFormatter.string(from: codeset.date))
                            //                                    .font(.custom("LuloOne", size: 12))
                            //                                    .foregroundColor(.gray)
                            //                            }
                        }
                        
                        // Top-center game clock
                        Spacer()
                        
                        //                        Group {
                        //                            if game.gameInteractive {
                        //                                Text("\(game.gameTimeRemaining)")
                        //                                    .font(.custom("LuloOne-Bold", size: 20))
                        //                                    .foregroundColor(.white)
                        //                                    .monospacedDigit()
                        //                                    .frame(minWidth: 54, alignment: .center)
                        //                                    .transition(.opacity)
                        //                            } else {
                        Text(" ")
                            .font(.custom("LuloOne-Bold", size: 20))
                            .frame(minWidth: 54)
                            .opacity(0)
                        //                            }
                        //                        }
                        
                        Spacer()
                        
                        //How to Play button
                        Button { showHowToPlay = true } label: {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.white)
                                .font(.title2)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 0)
                    
                    
                    Divider().background(.white).padding(20)
                    
                    //Spacer().frame(height:20)
                    
                    // Code display with animation
                    HStack(spacing: 10) {
                        ForEach(0..<game.numCols, id: \.self) { col in
                            Rectangle()
                                .frame(width: 45, height: 45)
                                .foregroundColor(
                                    game.isAnimating
                                    ? game.pegShades[game.animatedCode[col]]
                                    : (game.gameOver != 0 ? game.pegShades[game.theCode[col]] : game.myPegColor1)
                                )
                                .overlay(
                                    Text("?")
                                        .font(.custom("LuloOne-Bold", size: 14))
                                        .foregroundColor(
                                            game.isAnimating || game.gameOver != 0 ? .clear : .white
                                        )
                                )
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.white, lineWidth: 0.5)
                                )
                                .animation(.easeInOut(duration: 0.1), value: game.animatedCode)
                        }
                    }
                    .padding(8)
                    .scaleEffect(game.isAnimating ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: game.isAnimating)
                    
                    // Status text
                    Rectangle()
                        .frame(width: 300, height: 60)//game.gameOver != 0 && game.lastScore != nil ? 115 : 60)
                        .foregroundColor(.clear)
                        .overlay(
                            Text(game.statusText)
                                .font(.custom("LuloOne", size: game.gameOver != 0 && game.lastScore != nil ? 10 : 8))
                                .foregroundColor(.white)
                                .lineSpacing(3)
                                .multilineTextAlignment(.center)
                                .padding(8)
                        )
                    
                    Divider().background(.white).padding(5)
                    
                    // Game board
                    
                    VStack(spacing: 11) {
                        ForEach(0..<game.numRows, id: \.self) { row in
                            HStack(spacing: 8) {
                                ForEach(0..<game.numCols, id: \.self) { col in
                                    let currentColor = game.pegShades[game.theBoard[row][col]]
                                    let isEmpty = game.theBoard[row][col] == 0
                                    let isActiveRow = row == game.currentTurn
                                    let isSelectedSquare = selectedSquare.row == row && selectedSquare.col == col && showingColorPicker
                                    
                                    Rectangle()
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(1)
                                        .foregroundColor(
                                            // Show black when game is over
                                            game.gameOver != 0 ? Color.black :
                                                game.gameOver == 0 ? {
                                                    if isEmpty {
                                                        if isSelectedSquare {
                                                            return Color.gray.opacity(0.6)
                                                        } else if isActiveRow {
                                                            return Color.gray.opacity(0.3)
                                                        } else {
                                                            return Color.gray.opacity(0.15)
                                                        }
                                                    } else {
                                                        return currentColor
                                                    }
                                                }() : Color.black
                                        )
                                        .opacity(game.gameInteractive ? 1.0 : 0.7)
                                        .contentShape(Rectangle())
                                        .overlay(
                                            GeometryReader { geometry in
                                                Color.clear
                                                    .contentShape(Rectangle())
                                                    .onTapGesture {
                                                        guard row == game.currentTurn else {
                                                            if row > game.currentTurn { game.theBoard[row][col] = 0 }
                                                            return
                                                        }
                                                        
                                                        selectedSquare = (row: row, col: col)
                                                        
                                                        // Frame relative to the board coordinate space
                                                        let frame = geometry.frame(in: .named("GameBoardSpace"))
                                                        // Frame relative to the screen
                                                        let screenFrame = geometry.frame(in: .global)
                                                        
                                                        frameOffset = CGPoint(
                                                            x: screenFrame.midX - frame.midX,
                                                            y: screenFrame.midY - frame.midY
                                                        )
                                                        
                                                        // Use GameBoardSpace coordinates for picker
                                                        colorPickerPosition = CGPoint(x: screenFrame.midX, y: screenFrame.midY - frame.height - 34)
                                                        
                                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                            showingColorPicker = true
                                                        }
                                                        
                                                        // Don't immediately change status text - let it be handled by the picker
                                                    }
                                                    .allowsHitTesting(game.gameInteractive && !showingColorPicker && !showHowToPlay && !showEndGameOverlay && game.gameOver == 0)
                                            }
                                        )
                                    
                                }
                                
                                // Spacer before score button
                                //Rectangle().frame(width: 1, height: 10).foregroundColor(.clear)
                                
                                // Score indicators
                                ZStack {
                                    VStack {
                                        HStack {
                                            Circle()
                                                .frame(width: 10, height: 10)
                                                .foregroundColor(row < game.currentTurn ? game.scoreShades[game.theScore[row][0]] : .clear)
                                            Circle()
                                                .frame(width: 10, height: 10)
                                                .foregroundColor(row < game.currentTurn ? game.scoreShades[game.theScore[row][1]] : .clear)
                                        }
                                        HStack {
                                            Circle()
                                                .frame(width: 10, height: 10)
                                                .foregroundColor(row < game.currentTurn ? game.scoreShades[game.theScore[row][4]] : .clear)
                                            Circle()
                                                .frame(width: 10, height: 10)
                                                .foregroundColor(row < game.currentTurn ? game.scoreShades[game.theScore[row][2]] : .clear)
                                            Circle()
                                                .frame(width: 10, height: 10)
                                                .foregroundColor(row < game.currentTurn ? game.scoreShades[game.theScore[row][3]] : .clear)
                                        }
                                    }
                                    
                                    // Submit button with system image
                                    let isActiveRow = row == game.currentTurn
                                    let isRowComplete = isActiveRow && game.theBoard[row].allSatisfy { $0 != 0 }
                                    
                                    Image(systemName: isRowComplete ? "checkmark.circle.badge.questionmark.fill" : "checkmark.circle.badge.questionmark")
                                        .font(.system(size: 30))
                                        .foregroundColor(isActiveRow ? (game.gameOver == 0 ? (isRowComplete ? .white : .gray) : .clear) : .clear)
                                        .opacity(game.gameInteractive ? 1.0 : 0.5)
                                        .contentShape(Circle())
                                        .onTapGesture {
                                            if row == game.currentTurn {
                                                game.scoreRow(row)
                                            }
                                        }
                                        .allowsHitTesting(game.gameInteractive && !showingColorPicker && !showHowToPlay && !showEndGameOverlay && game.gameOver == 0)
                                }
                            }
                        }
                    }
                    .coordinateSpace(name: "GameBoardSpace") // board space for picker alignment
                    
                    Spacer()
                }
                .onChange(of: showHowToPlay, initial: false) { oldValue, newValue in
                    print("🔍 onChange showHowToPlay: \(oldValue) -> \(newValue)")
                    print("🔍 shouldAnimateAfterHowToPlay: \(shouldAnimateAfterHowToPlay)")
                    
                    if oldValue && !newValue {
                        print("🔍 How-to-play was dismissed")
                        
                        if shouldAnimateAfterHowToPlay {
                            print("🔍 Starting animation for first-time user")
                            game.startCodeAnimation()
                            shouldAnimateAfterHowToPlay = false
                        } else {
                            // Check if game is already in progress
                            if game.theCode.isEmpty {
                                // Game hasn't started yet - start it
                                print("🔍 Starting game for returning user")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    game.startGame()
                                }
                            } else {
                                // Game is already in progress - just resume
                                print("🔍 Resuming existing game")
                                // No action needed - game should continue where it left off
                            }
                        }
                    }
                }
                .onChange(of: game.gameOver, initial: false) { oldValue, newValue in
                    if newValue != 0 {
                        
                        //                        print("🔍 DEBUG: game.gameOver = \(newValue)")
                        //                        print("🔍 DEBUG: game.lastScore = \(String(describing: game.lastScore))")
                        //                        print("🔍 DEBUG: game.lastScore?.finalScore = \(String(describing: game.lastScore?.finalScore))")
                        //
                        // Show Code Reveal first
                        showCodeReveal = true
                        
                        //                        // After 2 seconds, hide reveal and show overlay
                        //                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        //                            withAnimation {
                        //                                showCodeReveal = false
                        //                                showEndGameOverlay = true
                        //                            }
                        //                        }
                    }
                }
            }
            
            // Color Picker Overlay
            if showingColorPicker {
                ColorPickerOverlay(
                    showingPicker: $showingColorPicker,
                    pickerPosition: $colorPickerPosition,
                    colors: Array(game.pegShades.dropFirst()),
                    onColorSelected: { colorIndex in
                        let gameColorIndex = colorIndex + 1
                        game.theBoard[selectedSquare.row][selectedSquare.col] = gameColorIndex
                        
                        // Check if row is now complete
                        let isRowComplete = game.theBoard[game.currentTurn].allSatisfy { $0 != 0 }
                        if isRowComplete {
                            game.statusText = "Tap the checkmark to submit your guess."
                        } else {
                            game.statusText = "Tap the checkmark when you're ready to submit a guess. You have \(7 - game.currentTurn) guesses left."
                        }
                    }
                )
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: SizePreferenceKey.self, value: geo.size)
                    }
                )
                .zIndex(1)
            }
            
            if game.showAlreadyPlayedOverlay {
                AlreadyPlayedOverlay(
                    targetDate: game.targetDate ?? Date(),
                    isVisible: $game.showAlreadyPlayedOverlay,
                    onPlayWithoutScore: { game.startGameWithoutScore() },
                    onPlayRandom: { game.startGameWithRandomCode() },
                    onNavigateToArchive: {
                        shouldNavigateToArchive = true
                        dismiss()
                    }
                )
                .zIndex(10)  // Behind how-to-play overlay
            }
            
            // How-to-Play Overlay ▢ ▢ ▢ ▢ ▢  ➜
            if showHowToPlay {
                HowToPlayOverlay(
                    gameID: game.gameInfo.id,
                    instructions: """
                    Crack the secret color code! 
                    
                    Each turn, tap a square in the row to assign a color. Colors can be resused. Check your pattern by tapping the circle.
                    
                    🟪 🟨 🟪 🟦 🟧  ➜   ⃝
                                            
                    Hints appear to guide you:
                    
                    🟢: Correct color & spot
                    🟡: Correct color, wrong spot:
                    
                    You get 7 tries. Solve it in less for higher scores! 
                    """,
                    isVisible: $showHowToPlay
                )
                .transition(.opacity)
                .zIndex(20)
            }
            
            // Game over overlay
            if game.gameOver > 0 {
                EndGameOverlay(
                    gameID: game.gameInfo.id,
                    finalScore: game.lastScore?.finalScore ?? 0,
                    displayName: game.gameInfo.displayName,
                    isVisible: .constant(true),
                    onPlayAgain: {
                        game.startGame()  // This will check for replay again
                        dismiss()
                    },
                    onHighScores: {
                        // Navigate to specific game leaderboard
                        navigateToSpecificLeaderboard = true
                        dismiss()
                    },
                    onMenu: {
                        dismiss()
                    },
                    timeElapsed: 300.0,
                    additionalInfo: game.willScoreCount ? nil : "Practice round - no score saved",
                    gameScore: game.lastScore
                )
                .zIndex(30)  // Top level
            }
            
            // Code Reveal Overlay
            if showCodeReveal {
//                let _ = print("game.currentTurn: \(game.currentTurn) vs game.numRows: \(game.numRows)")
//                let _ = print("game.gameOver: \(game.gameOver)")
//                let _ = print("game.currentTurn + 1: \(game.currentTurn+1)")
//                let _ = print("game.numRows: \(game.numRows)")
                
                CodeRevealOverlay(
                    theCode: game.theCode,
                    theBoard: game.theBoard,
                    lastTurn: game.currentTurn,
                    won: game.gameWon,
                    pegShades: game.pegShades
                ) {
                    withAnimation {
                        showCodeReveal = false
                        showEndGameOverlay = true
                    }
                }
                .transition(.opacity)
                .zIndex(40)
            }
        }
        //        .onDisappear {
        //            // When this view disappears, check if we should navigate to archive
        //            if shouldNavigateToArchive {
        //                // Pass the gameId in userInfo, not object
        //                NotificationCenter.default.post(
        //                    name: NSNotification.Name("NavigateToArchive"),
        //                    object: nil,
        //                    userInfo: ["gameId": "decode"]
        //                )
        //            }
        //        }
        .navigationDestination(isPresented: $navigateToSpecificLeaderboard) {
            MultiGameLeaderboardView(selectedGameID: game.gameInfo.id)
        }
        .navigationBarBackButtonHidden(
            game.gameOver > 0 ||
            showCodeReveal ||
            showEndGameOverlay ||
            showHowToPlay ||
            game.showAlreadyPlayedOverlay
        )
        .onAppear {
            //print("🔍 DecodeGameView onAppear - targetDate: \(String(describing: targetDate))")
            //print("🔍 Back button hidden? gameOver: \(game.gameOver), endGameOverlay: \(showEndGameOverlay), alreadyPlayedOverlay: \(game.showAlreadyPlayedOverlay)")
            
            // Handle game over state first
            if game.gameOver > 0 {
                print("🔄 Game was over, resetting...")
                showEndGameOverlay = false
                game.resetGame()
                return // Exit early, resetGame will trigger the initialization
            }
            
            // Normal initialization for new games
            if game.theCode.isEmpty {
                print("🔍 Game not initialized, starting initialization...")
                game.scoreManager = scoreManager
                
                let key = "hasSeenHowToPlay_decode"
                let hasSeenBefore = UserDefaults.standard.bool(forKey: key)
                
                print("🔍 hasSeenBefore: \(hasSeenBefore), isFirstLaunch: \(isFirstLaunch)")
                
                if !hasSeenBefore && isFirstLaunch {
                    print("🔍 Taking first-time user path")
                    
                    // Check if already played first
                    let gameDate = targetDate ?? Calendar.current.startOfDay(for: Date())
                    if scoreManager.isGameCompleted(gameId: "decode", date: gameDate) {
                        print("⚠️ Date \(gameDate) already played - showing overlay")
                        game.showAlreadyPlayedOverlay = true
                        game.willScoreCount = false
                    } else {
                        // Not played yet - proceed with first-time user flow
                        game.startGameWithoutAnimation()
                        showHowToPlay = true
                        shouldAnimateAfterHowToPlay = true
                    }
                } else {
                    print("🔍 Taking returning user path")
                    game.startGame() // This already has the check
                }
                isFirstLaunch = false
            }
            
            // MIXPANEL ANALYTICS CAPTURE
            Mixpanel.mainInstance().track(event: "Decode Game Page View", properties: [
                "app": "Decode! Daily iOS",
                "build_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"],
                "date": Date().formatted(),
                "subscription_tier": SubscriptionManager.shared.currentTier.displayName
            ])
            print("📈 🪵 MIXPANEL DATA LOG EVENT: Decode Game Page View")
            print("📈 🪵 date: \(Date().formatted())")
            print("📈 🪵 sub tier: \(SubscriptionManager.shared.currentTier.displayName)")
        }
        
    }
    
    
    // MARK: - Start New Game
    private func startNewGame() {
        showEndGameOverlay = false
        game.startGame()
    }
    
    struct SizePreferenceKey: PreferenceKey {
        static var defaultValue: CGSize = .zero
        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
            value = nextValue()
        }
    }
    
    // Legacy compatibility - keep this for now so existing navigation doesn't break
    typealias GameView = DecodeGameView
}

struct CodeRevealOverlay: View {
    let theCode: [Int]
    let theBoard: [[Int]]
    let lastTurn: Int
    let won: Bool
    let pegShades: [Color]
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            //won or loss text
            Text(won ? "You cracked the code!" : "Out of turns. \nBetter luck next time.")
                .font(.custom("LuloOne-Bold", size: 16))
                .foregroundColor(Color.myAccentColor1)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
            
            Spacer()
                .frame(height: 20)
            
            // dots
            Text("The code")
                .font(.custom("LuloOne", size: 18))
                .foregroundColor(.white)
            
            HStack {
                ForEach(Array(theCode.enumerated()), id: \.offset) { index, peg in
                    Circle()
                        .fill(pegShades[peg])
                        .frame(width: 30, height: 30)
                }
            }
            Spacer()
                .frame(height: 20)
            Text("Your guess")
                .font(.custom("LuloOne", size: 18))
                .foregroundColor(.white)
            
            HStack {
                ForEach(Array(theBoard[lastTurn].enumerated()), id: \.offset) { index, peg in
                    Circle()
                        .fill(pegShades[peg])
                        .frame(width: 30, height: 30)
                }
            }
            Spacer()
                .frame(height: 20)
            
            // tap text
            Text("Tap anywhere to continue")
                .font(.custom("LuloOne", size: 12))
                .foregroundColor(.gray)
                .padding(.top, 20)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .contentShape(Rectangle()) // 👈 makes whole area tappable
        .onTapGesture {
            onContinue()
        }
    }
}
