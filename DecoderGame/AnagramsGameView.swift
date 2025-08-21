//
//  AnagramsGameView.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/12/25.
//

import SwiftUI

struct AnagramsGameView: View {
    @StateObject private var game = AnagramsGame(scoreManager: GameScoreManager.shared)
    @EnvironmentObject var scoreManager: GameScoreManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showHowToPlay = false
    @State private var showEndGameOverlay = false
    @State private var hasStartedRound = false
    @State private var navigateToHighScores = false
    
    // Flash color for whole word
    @State private var answerFlashColor: Color? = nil
    
    private let instructionsText = """
    Unscramble as many words as you can in 60 seconds! ⏲
    
    Each turn, a set of scrambled letters will appear. Tap the letters to spell the correct word in the boxes a above.
    
    O  R  W  D   ➜   W  O  R  D 

    If you make a mistake, tap "clear" to remove the letters and try again. 
    
    Less guesses = Higher scores!
    """
    
    var body: some View {
        ZStack {
            NavigationStack {
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                    Spacer().frame(height:5)
                    
                    // Title + Timer + Help button
                    HStack {
                        Text(game.gameInfo.displayName)
                            .foregroundColor(.white)
                            .font(.custom("LuloOne-Bold", size: 20))
                            .onTapGesture { startRound() }

                        Spacer()

                        // Top-center game clock
                        Group {
                            if game.isGameActive {
                                Text("\(game.gameTimeRemaining)")
                                    .font(.custom("LuloOne-Bold", size: 20))
                                    .foregroundColor(.white)
                                    .monospacedDigit()
                                    .frame(minWidth: 54, alignment: .center)
                                    .transition(.opacity)
                            } else {
                                Text(" ")
                                    .font(.custom("LuloOne-Bold", size: 20))
                                    .frame(minWidth: 54)
                                    .opacity(0)
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
                    
                    Divider().background(.white).padding(5)
                    
                    Spacer().frame(height: 10)
                    
                    // Status text + symbol
                    VStack(spacing: 5) {
                        Text(game.statusText)
                            .foregroundColor(.white)
                            .font(.custom("LuloOne", size: 12))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 4)

                        if game.statusText.contains("Wrong") {
                            Image(systemName: "wrongwaysign.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.red)
                        } else if game.statusText.contains("Correct"){
                            Image(systemName: "checkmark.seal.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(Color.myAccentColor1)
                        } else if game.statusText.contains("Unscramble"){
                            Image(systemName: "shuffle.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "shuffle.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.clear)
                        }
                    }
                    
                    // === GAME BOARD ===
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
                            } else if game.isGameActive {
                                Spacer().frame(height:5)
                                gameArea
                                Spacer()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding([.leading, .trailing, .bottom], 20)
                    }
                    
                    Spacer()
                }
                .onAppear {
                    if UserDefaults.standard.bool(forKey: "hasSeenHowToPlay_anagrams") {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            startRound()
                        }
                    } else {
                        showHowToPlay = true
                    }
                }
                // UPDATED: Pause/resume game when overlay shows/hides
                .onChange(of: showHowToPlay, initial: false) { oldValue, newValue in
                    if newValue {
                        // Overlay is showing - pause the game
                        game.pauseGame()
                    } else {
                        // Overlay is hiding - resume the game
                        game.resumeGame()
                        
                        // Start only AFTER HowTo is dismissed at launch
                        if !hasStartedRound {
                            startRound()
                        }
                    }
                }
                .onChange(of: game.gameOver, initial: false) { oldValue, newValue in
                    if newValue == 1 {
                       showEndGameOverlay = true
                    }
                }
                .onChange(of: game.statusText) {
                    if game.statusText.contains("Correct") {
                        flashAnswer(correct: true)
                    } else if game.statusText.contains("Wrong") {
                        flashAnswer(correct: false)
                        
                        // Delay clearing so the red flash is visible
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            print("Wrong answer detected")
                            game.usedLetterIndices.removeAll()
                            game.userAnswer = ""
                            game.statusText = "Try again."
                        }
                    }
                }

                }
                .navigationDestination(isPresented: $navigateToHighScores) {
                    MultiGameLeaderboardView(selectedGameID: game.gameInfo.id)
                }
            }
            
            // Move overlays outside NavigationStack to root ZStack level
            if showEndGameOverlay {
                EndGameOverlay(
                    gameID: game.gameInfo.id,
                    finalScore: game.attempts,
                    displayName: game.gameInfo.displayName,
                    isVisible: $showEndGameOverlay,
                    onPlayAgain: { startNewGame() },
                    onHighScores: { navigateToHighScores = true },
                    onMenu: {
                        showEndGameOverlay = false
                        dismiss()
                    }
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
                    .transition(.opacity)
                }
            }
        }
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
                .frame(width: isScrambled ? 60 : 45, height: isScrambled ? 60 : 45)
                .background(
                    (flashColor != nil ? flashColor! :
                        (isUsed ? Color.gray.opacity(0.3) :
                            (isScrambled ? Color.white : Color.myAccentColor1)))
                )
                .clipShape(isScrambled ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 5)))
                .overlay(
                    Group {
                        if isScrambled {
                            Circle().stroke(Color.myAccentColor1, lineWidth: 3)
                        } else {
                            RoundedRectangle(cornerRadius: 0).stroke(Color.black, lineWidth: 1)
                        }
                    }
                )
                .shadow(radius: isUsed ? 1 : 2)
                .animation(.easeInOut(duration: 0.3), value: flashColor)
        }
        .disabled(!game.isGameActive || game.isGamePaused || isUsed)  // UPDATED: Also disable when paused
    }
    
    // MARK: - Scrambled Letters Grid
    private var scrambledLettersGrid: some View {
        let columns = Array(repeating: GridItem(.fixed(60), spacing: 5), count: 5)
        
        return LazyVGrid(columns: columns, spacing: 5) {
            ForEach(0..<game.scrambledLetters.count, id: \.self) { index in
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
    
    // MARK: - Game Area
    private var gameArea: some View {
        VStack(spacing: 15) {
            if game.isGameActive {
                Text("Score: \(game.attempts)")
                    .font(.custom("LuloOne-Bold", size: 16))
                    .foregroundColor(.white)
            }
            
            Spacer().frame(height: 40)
            
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
                        let _ = print("\(letter)") // ✅ allowed in ViewBuilder
                        letterButton(letter, isScrambled: false, isUsed: false, flashColor: answerFlashColor) {
                            game.removeLetter(at: index)
                        }
                    }
                    
                    ForEach(game.userAnswer.count..<game.currentWord.count, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 45, height: 45)
                            .cornerRadius(0)
                    }
                }
                .frame(minHeight: 55)
                
                Button("Clear all") {
                    game.clearAnswer()
                }
                .font(.custom("LuloOne", size: 12))
                .foregroundColor(game.userAnswer.isEmpty ? .gray : .white)
                .background(game.userAnswer.isEmpty ? Color.gray.opacity(0.3) : Color.red.opacity(0.7))
                .cornerRadius(8)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .disabled(game.userAnswer.isEmpty || game.isGamePaused)  // UPDATED: Also disable when paused
            }
            
            Spacer().frame(height: 35)
            
            // Scrambled letters grid
            VStack(spacing: 10) {
                Text("Scrambled Letters:")
                    .font(.custom("LuloOne", size: 14))
                    .foregroundColor(.white)
                
                scrambledLettersGrid
            }
            
        }
        //.padding(.horizontal, 20)
        .padding(.vertical, 30)
    }
    
    // MARK: - Start Control
    private func startRound() {
        guard !hasStartedRound else { return }
        hasStartedRound = true
        game.startGame()
    }
    
    private func startNewGame() {
        showEndGameOverlay = false
        hasStartedRound = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            startRound()
        }
    }
    
    // MARK: - Flash Answer
    private func flashAnswer(correct: Bool) {
        print("Flashing Answer...")
        answerFlashColor = correct ? .green : .red
        print("Answer flash color: \(answerFlashColor?.description ?? "nil")")
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
