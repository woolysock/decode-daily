//
//  DecodeGameView.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/14/25.
//

import SwiftUI

struct DecodeGameView: View {
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
    
    // Remove navigateToMenu since we'll use dismiss
    @State private var navigateToHighScores = false
    
    // Track if this is the first launch
    @State private var isFirstLaunch = true
    
    // Initialize with proper dependency injection
    init() {
        // Create a temporary game with a basic score manager that will be replaced
        self._game = StateObject(wrappedValue: DecodeGame(scoreManager: GameScoreManager.shared))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 15) {
                    // Title + How To Play button
                    HStack {
                        Text("\(game.gameInfo.displayName)")
                            .foregroundColor(.white)
                            .font(.custom("LuloOne-Bold", size: 20))
                            .onTapGesture {
                                game.startGame()
                            }
                        
                        Spacer()
                        
                        Button(action: {
                            showHowToPlay = true
                        }) {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.white)
                                .font(.title2)
                        }
                        .disabled(!game.gameInteractive)
                        .opacity(game.gameInteractive ? 1.0 : 0.5)
                    }
                    .padding(.horizontal, 20)
                    
                    Divider().background(.white).padding(5)
                    
                    // Code display with animation
                    HStack(spacing: 10) {
                        ForEach(0..<game.numCols, id: \.self) { col in
                            Rectangle()
                                .frame(width: 40, height: 40)
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
                                .animation(.easeInOut(duration: 0.1), value: game.animatedCode)
                        }
                    }
                    .scaleEffect(game.isAnimating ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: game.isAnimating)
                    
                    // Status text
                    Rectangle()
                        .frame(width: 300, height: game.gameOver != 0 && game.lastScore != nil ? 115 : 60)
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
                    // Game board
                    VStack(spacing: 11) {
                        ForEach(0..<game.numRows, id: \.self) { row in
                            HStack(spacing: 10) {
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
                                Rectangle().frame(width: 1, height: 10).foregroundColor(.clear)
                                
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
                }
                .onAppear {
                    // Inject the real scoreManager into the game
                    game.scoreManager = scoreManager
                    
                    // Check if user has seen How-to-Play before
                    let key = "hasSeenHowToPlay_decode"
                    let hasSeenBefore = UserDefaults.standard.bool(forKey: key)
                    
                    if !hasSeenBefore && isFirstLaunch {
                        // Start game without animation, then show how-to-play
                        game.startGameWithoutAnimation()
                        showHowToPlay = true
                    } else {
                        // Normal start with animation
                        game.startGame()
                    }
                    isFirstLaunch = false
                }
                .onChange(of: showHowToPlay, initial: false) { oldValue, newValue in
                    // When How-to-Play is dismissed, start the animation
                    if oldValue && !newValue {
                        game.startCodeAnimation()
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
                
                // How-to-Play Overlay ▢ ▢ ▢ ▢ ▢  ➜
                if showHowToPlay {
                    HowToPlayOverlay(
                        gameID: game.gameInfo.id,
                        instructions: """
                        Crack the secret color code! 
                        
                        You get 7 tries. Each turn, tap a square to assign a color. Check your pattern by tapping the circle.
                        
                        🟪 🟪 🟦 🟨  ➜   ⃝
                                                
                        Hints will appear to guide you:
                        🟢 : correct color & spot
                        🟡 : correct color but wrong spot 
                        
                        Less guesses yield higher scores!
                        """,
                        isVisible: $showHowToPlay
                    )
                    .transition(.opacity)
                    .zIndex(2)
                }
                
                // Code Reveal Overlay
                if showCodeReveal {
                    CodeRevealOverlay(
                        theCode: game.theCode,
                        theBoard: game.theBoard,
                        lastTurn: game.currentTurn,
                        won: game.gameOver == 1 && game.currentTurn < game.numRows,
                        pegShades: game.pegShades
                    ) {
                        withAnimation {
                            showCodeReveal = false
                            showEndGameOverlay = true
                        }
                    }
                    .transition(.opacity)
                    .zIndex(3)
                }

                
                // End Game Overlay
                if showEndGameOverlay {
                    EndGameOverlay(
                        gameID: game.gameInfo.id,
                        finalScore: game.lastScore?.finalScore ?? game.currentTurn,
                        displayName: game.gameInfo.displayName,
                        isVisible: $showEndGameOverlay,
                        onPlayAgain: { startNewGame() },
                        onHighScores: { navigateToHighScores = true },
                        onMenu: {
                            // Use dismiss instead of navigation
                            showEndGameOverlay = false
                            dismiss()
                        },
                        gameScore: game.lastScore
                    )
                    .transition(.opacity)
                    .zIndex(3)
                }
            }
            // Remove the navigationDestination for menu, keep only high scores
            .navigationDestination(isPresented: $navigateToHighScores) {
                MultiGameLeaderboardView(selectedGameID: game.gameInfo.id)
            }
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
        .background(Color.black.opacity(0.9).ignoresSafeArea())
        .contentShape(Rectangle()) // 👈 makes whole area tappable
        .onTapGesture {
            onContinue()
        }
    }
}
