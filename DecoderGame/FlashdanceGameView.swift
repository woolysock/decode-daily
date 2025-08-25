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

    // Navigation state (pushes leaderboard)
    @State private var navigateToHighScores = false

    // === Flash feedback state (kept) ===
    @State private var flashCardColor: Color = .white
    @State private var circleFlashColors: [Int: Color] = [:]

    // Instructions specific to Flashdance
    private let instructionsText = """
    You have 30 seconds to solve the
    most math problems! ⏲
    
    When a flashcard appears, swipe it towards the correct answer.
    
    [8 + 7]
    
    ⇠ ⇡ ⇢
    
    1         15         7

    Get streaks for bonus points!
    More right answers yield higher scores!
    """

    // Initialize with proper dependency injection
    init() {
        self._game = StateObject(wrappedValue: FlashdanceGame(scoreManager: GameScoreManager.shared))
    }

    // Render-time cleanup: remove trailing "Score: ..." from status text
    private var cleanedStatusText: String {
        let txt = game.statusText
        if let r = txt.range(of: "Score:") {
            return String(txt[..<r.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return txt
    }

    var body: some View {
        ZStack {
            // === Navigation container matches Anagrams ===
            NavigationStack {
                ZStack {
                    Color.black.ignoresSafeArea()

                    VStack(spacing: 15) {
                        Spacer().frame(height: 5)

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

                        // Status text (no score content)
                        Text(cleanedStatusText)
                            .foregroundColor(.white)
                            .font(.custom("LuloOne", size: 12))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)

                        Spacer(minLength: 0)

                        // === GAME BOARD ===
                        ZStack {
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
                                            .background(flashCardColor)
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
                                                        guard game.isGameActive && !game.isGamePaused else {
                                                            dragOffset = .zero
                                                            return
                                                        }
                                                        handleSwipe(value: value, geoSize: geo.size)
                                                    }
                                            )
                                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragOffset)
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            }
                            .padding([.leading, .trailing, .bottom], 20)
                        }

                        // === NEW: Scoreboard (bottom half area) ===
                        if game.isGameActive || game.gameOver == 1 {
                            Scoreboard(
                                score: game.totalScore,
                                correct: game.correctAttempts,
                                incorrect: game.incorrectAttempts,
                                streak: game.currentStreak
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 6)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        Spacer(minLength: 8)
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
                    // Pause/resume game when overlay shows/hides
                    .onChange(of: showHowToPlay, initial: false) { _, newValue in
                        if newValue {
                            game.pauseGame()
                        } else {
                            game.resumeGame()
                            if !hasStartedRound {
                                startRound()
                            }
                        }
                    }
                    .onChange(of: game.gameOver, initial: false) { _, newValue in
                        if newValue == 1 {
                            showEndGameOverlay = true
                        }
                    }
                }
                // Leaderboard lives on this stack
                .navigationDestination(isPresented: $navigateToHighScores) {
                    MultiGameLeaderboardView(selectedGameID: game.gameInfo.id)
                }
            }

            // === Overlays OUTSIDE the NavigationStack (match Anagrams) ===
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
                    finalScore: game.lastScore?.finalScore ?? game.totalScore,
                    displayName: game.gameInfo.displayName,
                    isVisible: $showEndGameOverlay,
                    onPlayAgain: { startNewGame() },
                    onHighScores: {
                        // Push leaderboard; no dismiss-on-pop handler
                        showEndGameOverlay = false
                        navigateToHighScores = true
                    },
                    onMenu: {
                        // Return to Main Menu
                        showEndGameOverlay = false
                        dismiss()
                    },
                    gameScore: game.lastScore   // ✅ pass the rich score object
                )
                .transition(.opacity)
            }
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
            flash(correct: true, selectedAnswer: selectedAnswer)
            withAnimation(.easeInOut(duration: 0.25)) {
                dragOffset = offsetForDirection(chosen)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                dragOffset = .zero
                game.newQuestion()
            }
        } else {
            flash(correct: false, selectedAnswer: selectedAnswer)
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

    // MARK: - Flash helper (kept)

    private func flash(correct: Bool, selectedAnswer: Int) {
        let color: Color = correct ? .green : .red

        flashCardColor = color
        circleFlashColors[selectedAnswer] = color

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeInOut(duration: 0.25)) {
                flashCardColor = .white
                circleFlashColors[selectedAnswer] = .white
            }
        }
    }

    // MARK: - Answer Circles

    private func answerCircle(_ value: Int) -> some View {
        Text("\(value)")
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.black)
            .frame(width: 50, height: 50)
            .background(circleFlashColors[value] ?? Color.white.opacity(0.9))
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

// MARK: - Scoreboard (bottom half)
private struct Scoreboard: View {
    let score: Int
    let correct: Int
    let incorrect: Int
    let streak: Int

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                StatPill(title: "Score", value: "\(score)")
                StatPill(title: "Correct", value: "\(correct)")
            }
            HStack(spacing: 12) {
                StatPill(
                    title: "Incorrect",
                    value: "\(incorrect)",
                    emphasize: incorrect > 0 ? .red : nil
                )
                StatPill(
                    title: "Streak",
                    value: "\(streak)",
                    emphasize: streak > 0 ? .green : nil
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: score)
        .animation(.easeInOut(duration: 0.2), value: correct)
        .animation(.easeInOut(duration: 0.2), value: incorrect)
        .animation(.easeInOut(duration: 0.2), value: streak)
    }
}

private struct StatPill: View {
    enum Emphasis { case green, red }
    let title: String
    let value: String
    var emphasize: Emphasis? = nil

    var body: some View {
        VStack(spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .kerning(1)

            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 56)
        .padding(.vertical, 8)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 3)
    }

    private var backgroundColor: Color {
        switch emphasize {
        case .green: return Color.green.opacity(0.35)
        case .red:   return Color.red.opacity(0.35)
        case .none:  return Color.white.opacity(0.10)
        }
    }

}

// Safe subscript so we don't crash
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
