//
//  FlashdanceGameView.swift
//  Decode! Daily iOS
//
//  Redesigned floating flashcard with pill answers
//

import SwiftUI

struct FlashdanceGameView: View {
    @EnvironmentObject var scoreManager: GameScoreManager
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var game: FlashdanceGame
    @StateObject private var dailyCheckManager = DailyCheckManager.shared
    
    @State private var dragOffset: CGSize = .zero
    @State private var showHowToPlay = false
    @State private var showEndGameOverlay = false
    @State private var hasStartedRound = false
    @State private var highlightedAnswer: Int? = nil
    @State private var navigateToHighScores = false
    
    // Flash feedback
    @State private var flashCardColor: Color = .white
    @State private var circleFlashColors: [Int: Color] = [:]
    
    // Animation states
    @State private var isAnimatingCorrect = false
    @State private var finalOffset: CGSize = .zero
    @State private var cardOpacity: Double = 1.0
    @State private var cardScale: CGFloat = 1.0
    
    private let instructionsText = """
    You have 30 seconds to solve the
    most math problems! ⏲
    
    When a flashcard appears, swipe it towards the correct answer.
    
    Get streaks for bonus points!
    More right answers yield higher scores!
    """
    
    init() {
        self._game = StateObject(wrappedValue: FlashdanceGame(scoreManager: GameScoreManager.shared))
    }
    
    private var cleanedStatusText: String {
        let txt = game.statusText
        if let r = txt.range(of: "Score:") {
            return String(txt[..<r.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return txt
    }
    
    var body: some View {
        ZStack {
            NavigationStack {
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    VStack(spacing: 15) {
                        Spacer().frame(height: 5)
                        
                        // === Header: Title + Timer + Help ===
                        HStack {
                            Text("\(game.gameInfo.displayName)")
                                .foregroundColor(.white)
                                .font(.custom("LuloOne-Bold", size: 20))
                                .onTapGesture { startRound() }
                            
                            Spacer()
                            
                            if game.isGameActive {
                                Text("\(game.gameTimeRemaining)")
                                    .font(.custom("LuloOne-Bold", size: 20))
                                    .foregroundColor(.white)
                                    .monospacedDigit()
                                    .frame(minWidth: 54)
                                    .transition(.opacity)
                            } else {
                                Text(" ")
                                    .font(.custom("LuloOne-Bold", size: 20))
                                    .frame(minWidth: 54)
                                    .opacity(0)
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
                        Text(cleanedStatusText)
                            .foregroundColor(.white)
                            .font(.custom("LuloOne", size: 12))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        Spacer().frame(height: 1)
                        
                        // === GAME BOARD ===
                        ZStack {
                            Color.black.ignoresSafeArea()
                            
                            GeometryReader { geo in
                                let cardWidth: CGFloat = min(geo.size.width * 0.6, 300)
                                let cardHeight: CGFloat = min(geo.size.height * 0.4, 420)
                                let pillWidth: CGFloat = min(geo.size.width * 0.25, 120)
                                let pillHeight: CGFloat = 160
                                let spacing: CGFloat = 10
                                
                                VStack {
                                    Spacer().frame(height: geo.size.height * 0.05)
                                    
                                    // === Answer Pills Row ===
                                    if game.isGameActive {
                                        HStack(spacing: spacing) {
                                            answerPill(game.answers[safe: 0] ?? 0)
                                                .frame(width: pillWidth, height: pillHeight)
                                            answerPill(game.answers[safe: 1] ?? 0)
                                                .frame(width: pillWidth, height: pillHeight)
                                            answerPill(game.answers[safe: 2] ?? 0)
                                                .frame(width: pillWidth, height: pillHeight)
                                        }
                                        .opacity(0.85)
                                    }
                                    
                                    Spacer().frame(height: 20)
                                    
                                    // === Flashcard Center ===
                                    if game.isPreCountdownActive {
                                        Text("\(game.countdownValue)")
                                            .font(.custom("LuloOne-Bold", size: 100))
                                            .foregroundColor(.white)
                                            .monospacedDigit()
                                            .scaleEffect(1.05)
                                            .transition(.scale)
                                    } else if game.isGameActive {
                                        Text(game.currentEquation)
                                            .padding(10)
                                            .foregroundColor(.black)
                                            .font(.custom("LuloOne-Bold", size: 40))
                                            .frame(width: cardWidth, height: cardHeight)
                                            .background(flashCardColor)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.myAccentColor1, lineWidth: 5)
                                            )
                                            .shadow(radius: 6)
                                            .scaleEffect(cardScale)
                                            .opacity(cardOpacity)
                                            .offset(isAnimatingCorrect ? finalOffset : dragOffset)
                                            .gesture(
                                                DragGesture(coordinateSpace: .named("GameBoard"))
                                                    .onChanged { value in
                                                        guard game.isGameActive && !game.isGamePaused && !isAnimatingCorrect else { return }
                                                        dragOffset = value.translation
                                                        
                                                        // Use absolute location in GameBoard coordinate space
                                                        highlightPillUnderDrag(location: value.location, geo: geo)
                                                    }
                                                    .onEnded { value in
                                                        guard game.isGameActive && !game.isGamePaused && !isAnimatingCorrect else {
                                                            return
                                                        }
                                                        
                                                        handleSwipeWithPills(location: value.location, geo: geo, currentDragOffset: value.translation, geoSize: geo.size)
                                                        highlightedAnswer = nil
                                                    }
                                            )
                                            .animation(.easeOut(duration: 0.8), value: isAnimatingCorrect ? finalOffset : dragOffset)
                                            .animation(.easeInOut(duration: 0.25), value: cardOpacity)
                                            .animation(.easeInOut(duration: 0.25), value: cardScale)
                                    }
                                    
                                    Spacer()
                                }
                                .frame(width: geo.size.width, height: geo.size.height)
                            }
                        }
                        .coordinateSpace(name: "GameBoard")
                        
                        // === Scoreboard at Bottom ===
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
                        game.scoreManager = scoreManager
                        if UserDefaults.standard.bool(forKey: "hasSeenHowToPlay_flashdance") {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { startRound() }
                        } else { showHowToPlay = true }
                    }
                    .onChange(of: showHowToPlay, initial: false) { _, newValue in
                        if newValue { game.pauseGame() }
                        else { game.resumeGame(); if !hasStartedRound { startRound() } }
                    }
                    .onChange(of: game.gameOver, initial: false) { _, newValue in
                        if newValue == 1 { showEndGameOverlay = true }
                    }
                }
                .navigationDestination(isPresented: $navigateToHighScores) {
                    MultiGameLeaderboardView(selectedGameID: game.gameInfo.id)
                }
            }
            
            // === Overlays ===
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
                        showEndGameOverlay = false
                        navigateToHighScores = true
                    },
                    onMenu: { showEndGameOverlay = false; dismiss() },
                    gameScore: game.lastScore
                )
                .transition(.opacity)
            }
        }
        .onChange(of: dailyCheckManager.showNewDayOverlay) { oldValue, newValue in
            if newValue {
                // New day overlay is showing - force end the game immediately
                print("FlashdanceGameView: Force ending game due to new day overlay")
                game.endGame()
                
                // Hide any other overlays that might be showing
                showEndGameOverlay = false
                showHowToPlay = false
                
                // Reset the game state
                hasStartedRound = false
            } else if oldValue == true && newValue == false {
                // Overlay was just dismissed - return to main menu
                print("FlashdanceGameView: New day overlay dismissed, returning to main menu")
                dismiss()
            }
        }
    }
    
    
    // MARK: - Pill answer helpers
    private func answerPill(_ value: Int) -> some View {
        let isHighlighted = highlightedAnswer == value
        return Text("\(value)")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .background(isHighlighted ? Color.myAccentColor2.opacity(0.9) : Color.myAccentColor1.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.2), lineWidth: 2))
            .shadow(radius: 3)
            .accessibilityLabel(Text("Answer \(value)"))
    }
    
//    private func highlightPillUnderDrag(location: CGPoint, geo: GeometryProxy) {
//        // Match the exact same calculations used in the UI layout
//        let pillWidth: CGFloat = min(geo.size.width * 0.25, 120)
//        let pillHeight: CGFloat = 160
//        let spacing: CGFloat = 10 // Match the HStack spacing exactly
//        
//        // Calculate the total width of all pills including spacing
//        let totalPillsWidth = pillWidth * 3 + spacing * 2
//        let startX = (geo.size.width - totalPillsWidth) / 2
//        
//        // Calculate Y position to match the actual pill layout
//        // Pills are positioned at: Spacer(height: geo.size.height * 0.05) + pillHeight/2
//        let pillRowY = geo.size.height * 0.05 + pillHeight / 2
//        
//        highlightedAnswer = nil
//        
//        for (i, val) in game.answers.enumerated() {
//            // Calculate the center X position for each pill
//            let pillCenterX = startX + pillWidth/2 + CGFloat(i) * (pillWidth + spacing)
//            
//            // Create the pill frame
//            let pillFrame = CGRect(
//                x: pillCenterX - pillWidth/2,
//                y: pillRowY - pillHeight/2,
//                width: pillWidth + 10,
//                height: pillHeight + 40
//            )
//            
//            if pillFrame.contains(location) {
//                highlightedAnswer = val
//                break
//            }
//        }
//    }
    
    private func highlightPillUnderDrag(location: CGPoint, geo: GeometryProxy) {
        // Calculate card center based on current drag
        let cardCenterX = geo.size.width / 2 + dragOffset.width
        
        highlightedAnswer = getAnswerUnderCardCenter(cardCenterX: cardCenterX, geo: geo)
    }
    
    private func handleSwipeWithPills(location: CGPoint, geo: GeometryProxy, currentDragOffset: CGSize, geoSize: CGSize) {
        let minSwipeThreshold: CGFloat = 40
        let upwardThreshold: CGFloat = -30
        
        // Check if we have enough swipe motion
        let swipeMagnitude = sqrt(currentDragOffset.width * currentDragOffset.width + currentDragOffset.height * currentDragOffset.height)
        
        guard swipeMagnitude >= minSwipeThreshold else {
            animateWrongAnswer()
            return
        }
        
        // Calculate the CENTER of the flashcard after the drag
        let cardCenterX = geo.size.width / 2 + currentDragOffset.width
        let cardCenterY = geo.size.height / 2 + currentDragOffset.height // Approximate card center Y
        
        var selectedAnswer: Int?
        
        if currentDragOffset.height <= upwardThreshold {
            // Card moved up enough - check which pill the card center is closest to
            selectedAnswer = getAnswerUnderCardCenter(cardCenterX: cardCenterX, geo: geo)
        }
        
        guard let selectedValue = selectedAnswer else {
            animateWrongAnswer()
            return
        }
        
        if game.checkAnswer(selected: selectedValue) {
            animateCorrectAnswer(dragOffset: currentDragOffset, geoSize: geoSize)
            flash(correct: true, selectedAnswer: selectedValue)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                game.newQuestion()
                resetCardAnimation()
            }
        } else {
            animateWrongAnswer()
            flash(correct: false, selectedAnswer: selectedValue)
        }
    }
    
    // MARK: - Animation Methods
    private func animateCorrectAnswer(dragOffset: CGSize, geoSize: CGSize) {
        isAnimatingCorrect = true
        
        // Calculate direction to fly offscreen
        let magnitude = sqrt(dragOffset.width * dragOffset.width + dragOffset.height * dragOffset.height)
        let normalizedX = magnitude > 0 ? dragOffset.width / magnitude : 0.0
        let normalizedY = magnitude > 0 ? dragOffset.height / magnitude : -1.0
        
        // Fly offscreen in the drag direction
        let flyDistance: CGFloat = max(geoSize.width, geoSize.height) + 200
        finalOffset = CGSize(
            width: normalizedX * flyDistance,
            height: normalizedY * flyDistance
        )
        
        // Use smoother, slower animations
        withAnimation(.easeOut(duration: 0.8)) {
            // Move the card offscreen
        }
        
        // Slightly delay and animate the scaling/opacity for better effect
        withAnimation(.easeInOut(duration: 0.6).delay(0.1)) {
            cardScale = 0.4
        }
        
        withAnimation(.easeOut(duration: 0.7).delay(0.2)) {
            cardOpacity = 0.0
        }
    }
    
    private func animateWrongAnswer() {
        // Bounce back to center
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            dragOffset = .zero
        }
    }
    
    private func resetCardAnimation() {
        isAnimatingCorrect = false
        finalOffset = .zero
        dragOffset = .zero
        cardOpacity = 1.0
        cardScale = 1.0
    }
    
    // MARK: - Flash
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
    
    // MARK: - Start control
    private func startRound() {
        guard !hasStartedRound else { return }
        hasStartedRound = true
        game.startGame()
    }
    
    private func startNewGame() {
        showEndGameOverlay = false
        hasStartedRound = false
        resetCardAnimation() // Reset animation state for new game
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { startRound() }
    }
    
    private func getAnswerUnderCardCenter(cardCenterX: CGFloat, geo: GeometryProxy) -> Int? {
        let pillWidth: CGFloat = min(geo.size.width * 0.25, 120)
        let spacing: CGFloat = 10
        let totalPillsWidth = pillWidth * 3 + spacing * 2
        let startX = (geo.size.width - totalPillsWidth) / 2
        
        // Check which pill the card center is closest to
        for (i, val) in game.answers.enumerated() {
            let pillCenterX = startX + pillWidth/2 + CGFloat(i) * (pillWidth + spacing)
            let pillLeftEdge = pillCenterX - pillWidth/2
            let pillRightEdge = pillCenterX + pillWidth/2
            
            // Add some tolerance for easier selection
            let tolerance: CGFloat = 20
            
            if cardCenterX >= (pillLeftEdge - tolerance) && cardCenterX <= (pillRightEdge + tolerance) {
                return val
            }
        }
        
        return nil
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

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
