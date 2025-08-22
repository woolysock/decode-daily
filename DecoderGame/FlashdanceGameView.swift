//
//  FlashdanceGameView.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/12/25.
//

import SwiftUI

struct FlashdanceGameView: View {
    @StateObject private var game: FlashdanceGame
    @EnvironmentObject var scoreManager: GameScoreManager
    @Environment(\.dismiss) private var dismiss
    @State private var dragOffset: CGSize = .zero
    @State private var showHowToPlay = false
    @State private var showEndGameOverlay = false
    @State private var hasStartedRound = false

    // Navigation states
    @State private var navigateToHighScores = false

    // Instructions specific to Flashdance
    private let instructionsText = """
    You have 30 seconds to solve the
    most math problems! ⏲
    
    When a flashcard appears, swipe it towards the correct answer.
    
    1         15         7   
    
    ⇠ ⇡ ⇢
    
    [8 + 7]

    More right answers = Higher scores!
    """

    // Initialize with proper dependency injection
    init() {
        self._game = StateObject(wrappedValue: FlashdanceGame(scoreManager: GameScoreManager.shared))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 15) {
                Spacer().frame(height:5)
                // Title + Timer + Help button
                HStack {
                    Text("\(game.gameInfo.displayName)")
                        .foregroundColor(.white)
                        .font(.custom("LuloOne-Bold", size: 20))
                        .onTapGesture { startRound() }

                    Spacer()

                    // Top-center game clock (shows only while playing)
                    Group {
                        if game.isGameActive {
                            Text("\(game.gameTimeRemaining)")
                                .font(.custom("LuloOne-Bold", size: 20))
                                .foregroundColor(.white)
                                .monospacedDigit()
                                .frame(minWidth: 54, alignment: .center)
                                .transition(.opacity)
                        } else {
                            // keep layout stable
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

                // GAME BOARD
                ZStack {
                    // Outer "border" area (keeps 20pt on L/R/B to create frame)
                    Color.black.ignoresSafeArea()

                    ZStack {
                        //Gameboard background color
                        Color.black.ignoresSafeArea()
                        
                        GeometryReader { geo in
                            // Answer circles (only while playing)
                            if game.isGameActive {
                                answerCircle(game.answers[safe: 0] ?? 0)
                                    .position(x: 40, y: geo.size.height / 3)

                                answerCircle(game.answers[safe: 1] ?? 0)
                                    .position(x: geo.size.width / 2, y: 60)

                                answerCircle(game.answers[safe: 2] ?? 0)
                                    .position(x: geo.size.width - 40, y: geo.size.height / 3)
                            }

                            // Center content: either big countdown or the flashcard
                            Group {
                                if game.isPreCountdownActive {
                                    Text("\(game.countdownValue)")
                                        .font(.custom("LuloOne-Bold", size: 100))
                                        .foregroundColor(.white)
                                        .monospacedDigit()
                                        .scaleEffect(1.05)
                                        .transition(.scale)
                                } else if game.isGameActive {
                                    // Flashcard
                                    Text(game.currentEquation)
                                        .padding(5)
                                        .foregroundColor(.black)
                                        .font(.custom("LuloOne-Bold", size: 40))
                                        .frame(width: 240, height: 300)
                                        .background(Color.white)
                                        .multilineTextAlignment(.center)
                                        .cornerRadius(5)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 5)
                                                .stroke(Color.myAccentColor1, lineWidth: 5)
                                        )
                                        .shadow(radius: 6)
                                        .offset(dragOffset)
                                        .gesture(
                                            DragGesture()
                                                .onChanged { value in
                                                    guard game.isGameActive && !game.isGamePaused else { return }
                                                    dragOffset = value.translation
                                                }
                                                .onEnded { value in
                                                    guard game.isGameActive && !game.isGamePaused else { dragOffset = .zero; return }
                                                    handleSwipe(value: value, geoSize: geo.size)
                                                }
                                        )
                                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragOffset)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        }
                    }
                    .padding([.leading, .trailing, .bottom], 20) // 20pt "border" on three sides
                }
                
                Spacer()
            }
            .onAppear {
                // Inject the real scoreManager into the game
                game.scoreManager = scoreManager
                
                // If user has already seen HowTo, start automatically after a small delay.
                if UserDefaults.standard.bool(forKey: "hasSeenHowToPlay_flashdance") {
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

            // Overlays
            if showHowToPlay {
                HowToPlayOverlay(
                    gameID: game.gameInfo.id,
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
                    onMenu: {
                        // Use dismiss instead of navigation
                        showEndGameOverlay = false
                        dismiss()
                    }
                )
                .transition(.opacity)
            }
        }
        .navigationDestination(isPresented: $navigateToHighScores) {
            MultiGameLeaderboardView(selectedGameID: game.gameInfo.id)
        }
    }

    // MARK: - Swipe Logic

    private func handleSwipe(value: DragGesture.Value, geoSize: CGSize) {
        let horizontal = value.translation.width
        let vertical = value.translation.height

        var chosenPosition: AnswerPosition?
        if abs(horizontal) > abs(vertical) {
            chosenPosition = horizontal > 0 ? .right : .left
        } else if vertical < 0 {
            chosenPosition = .top
        }

        guard let chosen = chosenPosition else {
            dragOffset = .zero
            return
        }

        let selectedAnswer: Int
        switch chosen {
        case .left:  selectedAnswer = game.answers[safe: 0] ?? Int.min
        case .top:   selectedAnswer = game.answers[safe: 1] ?? Int.min
        case .right: selectedAnswer = game.answers[safe: 2] ?? Int.min
        }

        if game.checkAnswer(selected: selectedAnswer) {
            withAnimation(.easeInOut(duration: 0.25)) {
                dragOffset = offsetForDirection(chosen)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                dragOffset = .zero
                game.newQuestion()
            }
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                dragOffset = .zero
            }
        }
    }

    private func offsetForDirection(_ pos: AnswerPosition) -> CGSize {
        switch pos {
        case .left:  return CGSize(width: -320, height: 0)
        case .top:   return CGSize(width: 0, height: -320)
        case .right: return CGSize(width: 320, height: 0)
        }
    }

    // MARK: - Answer Circles

    private func answerCircle(_ value: Int) -> some View {
        Text("\(value)")
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.black)
            .frame(width: 50, height: 50)
            .background(Color.white.opacity(0.9))
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.black, lineWidth: 1))
            .shadow(radius: 2)
            .accessibilityLabel(Text("Answer \(value)"))
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

// Safe subscript so we don't crash
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
