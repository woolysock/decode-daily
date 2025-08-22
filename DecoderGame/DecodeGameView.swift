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
                    }
                    .padding(.horizontal, 20)
                    
                    Divider().background(.white).padding(5)
                    
                    // Code display
                    HStack(spacing: 10) {
                        ForEach(0..<game.numCols, id: \.self) { col in
                            Rectangle()
                                .frame(width: 40, height: 40)
                                .foregroundColor(game.gameOver != 0 ? game.pegShades[game.theCode[col]] : game.myPegColor1)
                                .overlay(
                                    Text("?")
                                        .font(.custom("LuloOne-Bold", size: 14))
                                        .foregroundColor(game.gameOver == 0 ? .white : .clear)
                                )
                        }
                    }
                    
                    // Status text
                    Rectangle()
                        .frame(width: 300, height: game.gameOver != 0 && game.lastScore != nil ? 120 : 60)
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
                    VStack(spacing: 10) {
                        ForEach(0..<game.numRows, id: \.self) { row in
                            HStack(spacing: 10) {
                                ForEach(0..<game.numCols, id: \.self) { col in
                                    let currentColor = game.pegShades[game.theBoard[row][col]]
                                    
                                    Rectangle()
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(1)
                                        .foregroundColor(
                                            game.gameOver == 0
                                            ? (row <= game.currentTurn ? currentColor : .clear)
                                            : (row != game.currentTurn - 1 ? currentColor.opacity(0.6) : currentColor)
                                        )
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
                                                        
                                                        game.statusText = "Choose a color for this square."
                                                    }
                                                    .allowsHitTesting(!showingColorPicker && !showHowToPlay && !showEndGameOverlay)
                                            }
                                        )
                                    
                                }
                                
                                // Spacer before score button
                                Rectangle().frame(width: 10, height: 10).foregroundColor(.clear)
                                
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
                                                .foregroundColor(row < game.currentTurn ? game.scoreShades[game.theScore[row][2]] : .clear)
                                            Circle()
                                                .frame(width: 10, height: 10)
                                                .foregroundColor(row < game.currentTurn ? game.scoreShades[game.theScore[row][3]] : .clear)
                                        }
                                    }
                                    
                                    // Circle that submits the score
                                    Circle()
                                        .frame(width: 50)
                                        .foregroundColor(row == game.currentTurn ? (game.gameOver == 0 ? .gray : .clear) : .clear)
                                        .contentShape(Circle())
                                        .onTapGesture {
                                            if row == game.currentTurn {
                                                game.scoreRow(row)
                                            }
                                        }
                                        .allowsHitTesting(!showingColorPicker && !showHowToPlay && !showEndGameOverlay)
                                }
                            }
                        }
                    }
                    .coordinateSpace(name: "GameBoardSpace") // board space for picker alignment
                }
                .onAppear {
                    // Inject the real scoreManager into the game
                    game.scoreManager = scoreManager
                    
                    // Show the How-to-Play overlay if the user hasn't dismissed it before
                    let key = "hasSeenHowToPlay_decode"
                    if !UserDefaults.standard.bool(forKey: key) {
                        showHowToPlay = true
                    }
                }
                .onChange(of: game.gameOver, initial: false) { oldValue, newValue in
                    if newValue != 0 {
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
                            game.statusText = "Tap the circle when you're ready to submit a guess."
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
                        
                        Each turn, tap a square to assign a color. Check your pattern by tapping the circle.
                        
                        🟪 🟪 🟦 🟨  ➜   ⃝
                                                
                        Hints will appear to guide you:
                        🟢 : correct color & spot
                        🟡 : correct color but wrong spot 
                        
                        Less guesses = Higher scores!
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
                        lastTurn: game.currentTurn - 1,
                        won: game.lastScore?.won ?? false,
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
                        finalScore: game.currentTurn, // Using currentTurn as the score (number of attempts)
                        displayName: game.gameInfo.displayName,
                        isVisible: $showEndGameOverlay,
                        onPlayAgain: { startNewGame() },
                        onHighScores: { navigateToHighScores = true },
                        onMenu: {
                            // Use dismiss instead of navigation
                            showEndGameOverlay = false
                            dismiss()
                        }
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
                ForEach(theCode, id: \.self) { peg in
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
                ForEach(theBoard[lastTurn], id: \.self) { peg in
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
