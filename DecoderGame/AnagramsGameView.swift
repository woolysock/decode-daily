import SwiftUI

struct AnagramsGameView: View {
    @StateObject private var game = AnagramsGame(scoreManager: GameScoreManager.shared)
    @EnvironmentObject var scoreManager: GameScoreManager
    
    @State private var showHowToPlay = false
    @State private var showEndGameOverlay = false
    @State private var hasStartedRound = false   // ensure we only auto-start once
    
    // 👇 New navigation states
    @State private var navigateToMenu = false
    @State private var navigateToHighScores = false

    // Instructions specific to Anagrams
    private let instructionsText = """
    Race against the clock to unscramble as many words as you can.
    
    How to play:
    You'll see a scrambled set of letters. Tap letters to spell the correct word in the boxes at the top.
    
    O R W D  →  W O R D 

    Tap letters in your answer to remove them, or tap clear to remove all letters.
    
    The more words you unscramble, the higher your score!
    """

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 15) {
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

                    // Status text
                    Text(game.statusText)
                        .foregroundColor(.white)
                        .font(.custom("LuloOne", size: 12))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    Spacer()

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
                                // Game area when game is active
                                gameArea
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
                .onChange(of: showHowToPlay, initial: false) { oldValue, newValue in
                    if !newValue && !hasStartedRound {
                        startRound()
                    }
                }
                .onChange(of: game.gameOver, initial: false) { oldValue, newValue in
                    if newValue == 1 {
                       showEndGameOverlay = true
                    }
                }

                // Overlays
                if showHowToPlay {
                    HowToPlayOverlay(
                        gameID: game.gameInfo.id,
                        //displayName: game.gameInfo.displayName,
                        instructions: instructionsText,
                        isVisible: $showHowToPlay
                    )
                    .transition(.opacity)
                }
                
                if showEndGameOverlay {
                    EndGameOverlay(
                        gameID: game.gameInfo.id,
                        finalScore: game.attempts,
                        displayName: game.gameInfo.displayName,
                        isVisible: $showEndGameOverlay,
                        onPlayAgain: { startNewGame() },
                        onHighScores: { navigateToHighScores = true },
                        onMenu: { navigateToMenu = true }               // 👈
                    )
                    .transition(.opacity)
                }
            }
            // Hidden navigation links (triggered by state)
            .navigationDestination(isPresented: $navigateToMenu) {
                MainMenuView()
            }
            .navigationDestination(isPresented: $navigateToHighScores) {
                MultiGameLeaderboardView(selectedGameID: game.gameInfo.id)
            }
            
        }
    }

    // MARK: - Letter Button Component
    private func letterButton(_ letter: String, isScrambled: Bool, isUsed: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(isUsed ? "" : letter)
                .font(.custom("LuloOne-Bold", size: 20))
                .foregroundColor(.black)
                .frame(width: 45, height: 45)
                .background(
                    isUsed ? Color.gray.opacity(0.3) :
                    (isScrambled ? Color.white : Color.myAccentColor1)
                )
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.black, lineWidth: 1)
                )
                .shadow(radius: isUsed ? 1 : 2)
        }
        .disabled(!game.isGameActive || isUsed)
    }

    // MARK: - Game Area
    private var gameArea: some View {
        VStack(spacing: 15) {
            // User's answer
            VStack(spacing: 10) {
                Text("Your Answer:")
                    .font(.custom("LuloOne", size: 14))
                    .foregroundColor(.white)
                
                HStack(spacing: 5) {
                    ForEach(0..<game.userAnswer.count, id: \.self) { index in
                        let letter = String(game.userAnswer[game.userAnswer.index(game.userAnswer.startIndex, offsetBy: index)])
                        letterButton(letter, isScrambled: false, isUsed: false) {
                            game.removeLetter(at: index)
                        }
                    }
                    
                    ForEach(game.userAnswer.count..<game.currentWord.count, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 45, height: 45)
                            .cornerRadius(5)
                    }
                }
                .frame(minHeight: 55)
                
                Button("Clear all") {
                    game.clearAnswer()
                }
                .font(.custom("LuloOne", size: 12))
                .foregroundColor(game.userAnswer.isEmpty ? .gray : .white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(game.userAnswer.isEmpty ? Color.gray.opacity(0.3) : Color.red.opacity(0.7))
                .cornerRadius(8)
                .disabled(game.userAnswer.isEmpty)
            }
            
            Spacer().frame(height: 35)
            
            // Scrambled letters
            VStack(spacing: 10) {
                Text("Scrambled Letters:")
                    .font(.custom("LuloOne", size: 14))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
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
                .frame(minHeight: 85)
            }
            
            // Score
            if game.isGameActive {
                Text("Score: \(game.attempts)")
                    .font(.custom("LuloOne-Bold", size: 16))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Start control
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
}
