//
//  FlashdanceGameView.swift
//  Decode! Daily iOS
//
//  Redesigned floating flashcard with pill answers
//

import SwiftUI
import Mixpanel

struct FlashdanceGameView: View {
    let targetDate: Date?
    
    //@EnvironmentObject var scoreManager: GameScoreManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sizeCategory) var sizeCategory
    
    @ObservedObject private var equationManager = DailyEquationManager.shared
    
    @StateObject private var game: FlashdanceGame
    @StateObject private var dailyCheckManager = DailyCheckManager.shared
    @State private var finalGameData: GameScore?
    @State private var navigateToSpecificLeaderboard = false
    
    @State private var dragOffset: CGSize = .zero
    @State private var showHowToPlay = false
    @State private var showEndGameOverlay = false
    @State private var hasStartedRound = false
    @State private var highlightedAnswer: Int? = nil
    @State private var navigateToHighScores = false
    @State private var showDebugZones = false // Debug toggle
    
    // Flash feedback
    @State private var flashCardColor: Color = .white
    @State private var circleFlashColors: [Int: Color] = [:]
    
    // Animation states
    @State private var isAnimatingCorrect = false
    @State private var finalOffset: CGSize = .zero
    @State private var cardOpacity: Double = 1.0
    @State private var cardScale: CGFloat = 1.0
    
    let scoreManager = GameScoreManager.shared
    
    private let instructionsText = """
    Race against the clock to solve the most math problems!  ×  +  −  ÷
    
    When a flashcard appears in the center of the screen, swipe it towards the correct answer.
    
      ✅ Right answers earn big.
      🔥 Get streaks for bonus points!
      ☠️ Avoid wrong answers. 
    
    You have 30 seconds to solve as many as you can.
    
    """
    
    init(targetDate: Date? = nil) {
        print("🏁 FlashdanceGameView init() with targetDate = \(String(describing: targetDate))")
        //print("🏁 Call stack: \(Thread.callStackSymbols.prefix(5))")
        self.targetDate = targetDate
        self._game = StateObject(wrappedValue: FlashdanceGame(scoreManager: GameScoreManager.shared, targetDate: targetDate))
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
                        
                        HStack {
                            Spacer().frame(width: 5)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text("\(game.gameInfo.displayName)")
                                        .foregroundColor(.white)
                                        .font(.custom("LuloOne-Bold", size: 20))
                                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                        .lineLimit(1)
                                        .allowsTightening(true)
                                        .onTapGesture { startRound() }
                                    
                                    // Archive indicator
                                    if targetDate != nil {
                                        Text("ARCHIVE")
                                            .font(.custom("LuloOne", size: 8))
                                            .foregroundColor(.orange)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.orange.opacity(0.2))
                                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                            .lineLimit(1)
                                            .allowsTightening(true)
                                            .cornerRadius(4)
                                    }
                                }
                                
                                if let targetDate = targetDate {
                                    // Show the archive date when in archive mode
                                    Text(DateFormatter.dayFormatter.string(from: targetDate))
                                        .font(.custom("LuloOne", size: 12))
                                        .foregroundColor(.gray)
                                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                        .lineLimit(1)
                                        .allowsTightening(true)
                                } else if let mathset = equationManager.currentEquationSet {
                                    // Show the equation set date when in normal mode
                                    
                                    Text(DateFormatter.dayStringFormatter.string(from: mathset.date))
                                        .font(.custom("LuloOne", size: 12))
                                        .foregroundColor(.gray)
                                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                        .lineLimit(1)
                                        .allowsTightening(true)
                                }
                            }
                            
                            Spacer()
                            
                            Group {
                                
                                if game.isGameActive {
                                    Text("\(game.gameTimeRemaining)")
                                        .font(.custom("LuloOne-Bold", size: 20))
                                        .foregroundColor(.white)
                                        .monospacedDigit()
                                        .frame(minWidth: 54)
                                        .transition(.opacity)
                                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                        .lineLimit(1)
                                        .allowsTightening(true)
                                } else {
                                    Text(" ")
                                        .font(.custom("LuloOne-Bold", size: 20))
                                        .frame(minWidth: 54)
                                        .opacity(0)
                                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                        .lineLimit(1)
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
                        
                        //Spacer().frame(height:1)
                        
                        Divider().background(.white).padding(5)
                        
                        // Status text
                        Text(cleanedStatusText)
                            .foregroundColor(.white)
                            .font(.custom("LuloOne", size: 12))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                            .lineLimit(4, reservesSpace: true)
                            .allowsTightening(true)
                            .padding(.horizontal, 20)
                        
                        Spacer().frame(height:45)
                        
                        // === GAME BOARD ===
                        ZStack {
                            Color.black.ignoresSafeArea()
                            
                            GeometryReader { geo in
                                let cardWidth: CGFloat = 180
                                let cardHeight: CGFloat = 200
                                let pillWidth: CGFloat = 120
                                let pillHeight: CGFloat = 50
                                let spacing: CGFloat = 10
                                
                                ZStack {
                                    // Debug zones overlay
                                    //                                    if showDebugZones {
                                    //                                        debugZonesView(geo: geo, pillWidth: pillWidth, spacing: spacing)
                                    //                                    }
                                    
                                    VStack {
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
                                        
                                        Spacer().frame(height: 10)
                                        
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
                        }
                        .coordinateSpace(name: "GameBoard")
                        .onTapGesture(count: 3) { // Triple tap to toggle debug zones
                            showDebugZones.toggle()
                        }
                        
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
                        if newValue == 1 {
                            let archiveDate = game.targetDate ?? Date()
                            
                            // Create a GameScore with the current game data
                            let additionalProps = FlashdanceAdditionalProperties(
                                gameDuration: 30,
                                correctAnswers: game.correctAttempts,
                                incorrectAnswers: game.incorrectAttempts,
                                longestStreak: game.maxStreak,
                                gameDate: archiveDate
                            )
                            
                            finalGameData = GameScore(
                                gameId: "flashdance",
                                date: Date(),
                                archiveDate: archiveDate,
                                attempts: game.correctAttempts + game.incorrectAttempts,
                                timeElapsed: 30.0,
                                won: true,
                                finalScore: game.totalScore,
                                additionalProperties: additionalProps
                            )
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showEndGameOverlay = true
                            }
                        }
                    }
                    
                }
                .navigationDestination(isPresented: $navigateToSpecificLeaderboard) {
                    MultiGameLeaderboardView(selectedGameID: game.gameInfo.id)
                }
                .navigationBarBackButtonHidden(
                    game.gameOver > 0 ||
                    showEndGameOverlay ||
                    showHowToPlay
                )
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
            
            // Move overlays outside NavigationStack to root ZStack level
            
            if showEndGameOverlay {
                EndGameOverlay(
                    gameID: game.gameInfo.id,
                    finalScore: finalGameData?.finalScore ?? game.totalScore,
                    displayName: game.gameInfo.displayName,
                    isVisible: $showEndGameOverlay,
                    onPlayAgain: { startNewGame() },
                    onHighScores: {
                        // Navigate to specific game leaderboard
                        navigateToSpecificLeaderboard = true
                        dismiss()
                    },
                    onMenu: {
                        showEndGameOverlay = false
                        dismiss()
                    },
                    gameScore: finalGameData  // Now this is a GameScore object
                )
                .transition(.opacity)
            }
        }
        .onChange(of: dailyCheckManager.showNewDayOverlay) { oldValue, newValue in
            // Only respond to new day overlay if this is NOT an archived game
            if targetDate == nil {
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
        .onAppear {
            if game.gameOver > 0 {
                game.resetGame()
            }
            
            // MIXPANEL ANALYTICS CAPTURE
            Mixpanel.mainInstance().track(event: "Flashdance Game Page View", properties: [
                "app": "Decode! Daily iOS",
                "build_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"],
                "date": Date().formatted(),
                "subscription_tier": SubscriptionManager.shared.currentTier.displayName
            ])
            print("📈 🪵 MIXPANEL DATA LOG EVENT: Flashdance Game Page View")
            print("📈 🪵 date: \(Date().formatted())")
            print("📈 🪵 sub tier: \(SubscriptionManager.shared.currentTier.displayName)")
            
        }
    }
    
    //    // MARK: - Debug Zones View
    //    @ViewBuilder
    //    private func debugZonesView(geo: GeometryProxy, pillWidth: CGFloat, spacing: CGFloat) -> some View {
    //        let totalPillsWidth = pillWidth * 3 + spacing * 2
    //        let startX = (geo.size.width - totalPillsWidth) / 2
    //        let horizontalTolerance: CGFloat = 15
    //
    //        // Calculate what would be selected if we let go right now
    //        let cardCenterX = geo.size.width / 2 + dragOffset.width
    //        let wouldSelect = getAnswerUnderCardCenter(cardCenterX: cardCenterX, geo: geo)
    //
    //        // Calculate swipe validation
    //        let minSwipeThreshold: CGFloat = 10  // Updated to match handleSwipeWithPills
    //        let minUpwardMovement: CGFloat = -10  // Updated to match handleSwipeWithPills
    //        let horizontalDistance = abs(dragOffset.width)
    //        let swipeMagnitude = sqrt(dragOffset.width * dragOffset.width + dragOffset.height * dragOffset.height)
    //        let hasEnoughSwipe = horizontalDistance >= 10 || swipeMagnitude >= minSwipeThreshold  // Updated to match
    //        let hasValidDirection = dragOffset.height <= minUpwardMovement || horizontalDistance >= 20 || swipeMagnitude >= 35  // Updated to match
    //        let wouldBeValid = hasEnoughSwipe && hasValidDirection && wouldSelect != nil
    //
    //        ForEach(0..<3, id: \.self) { i in
    //            let pillCenterX = startX + pillWidth/2 + CGFloat(i) * (pillWidth + spacing)
    //            let zoneLeftEdge = pillCenterX - pillWidth/2 - horizontalTolerance
    //            let zoneRightEdge = pillCenterX + pillWidth/2 + horizontalTolerance
    //            let zoneWidth = zoneRightEdge - zoneLeftEdge
    //            let answerValue = game.answers[safe: i] ?? 0
    //            let isSelectedZone = wouldSelect == answerValue
    //
    //            Rectangle()
    //                .fill(isSelectedZone ? Color.green.opacity(0.4) : Color.red.opacity(0.3))
    //                .frame(width: zoneWidth, height: geo.size.height)
    //                .position(x: pillCenterX, y: geo.size.height / 2)
    //                .overlay(
    //                    VStack {
    //                        Text("Zone \(i + 1)")
    //                            .font(.caption)
    //                            .foregroundColor(.white)
    //                            .padding(.horizontal, 4)
    //                            .background(Color.black.opacity(0.7))
    //                            .cornerRadius(4)
    //
    //                        Spacer()
    //
    //                        Text("Answer: \(answerValue)")
    //                            .font(.caption)
    //                            .foregroundColor(.white)
    //                            .padding(.horizontal, 4)
    //                            .background(isSelectedZone ? Color.green.opacity(0.8) : Color.black.opacity(0.7))
    //                            .cornerRadius(4)
    //
    //                        if isSelectedZone {
    //                            Text("SELECTED")
    //                                .font(.caption2)
    //                                .foregroundColor(.white)
    //                                .padding(.horizontal, 4)
    //                                .background(Color.green)
    //                                .cornerRadius(4)
    //                        }
    //                    }
    //                    .padding(.vertical, 20)
    //                )
    //        }
    //
    //        // Show card center position with validation status
    //        Circle()
    //            .fill(wouldBeValid ? Color.green : Color.yellow)
    //            .frame(width: 12, height: 12)
    //            .position(x: geo.size.width / 2 + dragOffset.width, y: geo.size.height / 2 + dragOffset.height)
    //            .overlay(
    //                Circle()
    //                    .stroke(Color.white, lineWidth: 2)
    //                    .frame(width: 12, height: 12)
    //                    .position(x: geo.size.width / 2 + dragOffset.width, y: geo.size.height / 2 + dragOffset.height)
    //            )
    //
    //        // Show coordinate info with prediction
    //        VStack {
    //            Spacer()
    //            HStack {
    //                VStack(alignment: .leading, spacing: 2) {
    //                    Text("Debug Info:")
    //                        .font(.caption)
    //                        .foregroundColor(.white)
    //                        .fontWeight(.bold)
    //
    //                    Text("Card Center X: \(Int(cardCenterX))")
    //                        .font(.caption)
    //                        .foregroundColor(.white)
    //
    //                    Text("Currently Highlighted: \(highlightedAnswer?.description ?? "None")")
    //                        .font(.caption)
    //                        .foregroundColor(.white)
    //
    //                    Divider().background(Color.white.opacity(0.5))
    //
    //                    if wouldBeValid {
    //                        Text("✅ Would Select: \(wouldSelect?.description ?? "None")")
    //                            .font(.caption)
    //                            .foregroundColor(.green)
    //                            .fontWeight(.bold)
    //                    } else {
    //                        Text("❌ Would Reject")
    //                            .font(.caption)
    //                            .foregroundColor(.red)
    //                            .fontWeight(.bold)
    //
    //                        if !hasEnoughSwipe {
    //                            Text("• Not enough swipe distance")
    //                                .font(.caption2)
    //                                .foregroundColor(.orange)
    //                        }
    //                        if !hasValidDirection {
    //                            Text("• Invalid swipe direction")
    //                                .font(.caption2)
    //                                .foregroundColor(.orange)
    //                        }
    //                        if wouldSelect == nil {
    //                            Text("• No zone detected")
    //                                .font(.caption2)
    //                                .foregroundColor(.orange)
    //                        }
    //                    }
    //
    //                    Divider().background(Color.white.opacity(0.5))
    //
    //                    Text("Swipe: H:\(Int(dragOffset.width)) V:\(Int(dragOffset.height))")
    //                        .font(.caption2)
    //                        .foregroundColor(.gray)
    //
    //                    Text("Triple-tap to hide")
    //                        .font(.caption2)
    //                        .foregroundColor(.yellow)
    //                }
    //                .padding(8)
    //                .background(Color.black.opacity(0.9))
    //                .cornerRadius(8)
    //                Spacer()
    //            }
    //        }
    //        .padding()
    //    }
    
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
    
    
    private func highlightPillUnderDrag(location: CGPoint, geo: GeometryProxy) {
        // Calculate card center based on current drag
        let cardCenterX = geo.size.width / 2 + dragOffset.width
        
        highlightedAnswer = getAnswerUnderCardCenter(cardCenterX: cardCenterX, geo: geo)
    }
    
    private func handleSwipeWithPills(location: CGPoint, geo: GeometryProxy, currentDragOffset: CGSize, geoSize: CGSize) {
        let minSwipeThreshold: CGFloat = 40
        let minUpwardMovement: CGFloat = -20  // Reduced from -30, less strict
        
        // Check if we have enough horizontal swipe motion (prioritize horizontal)
        let horizontalDistance = abs(currentDragOffset.width)
        let swipeMagnitude = sqrt(currentDragOffset.width * currentDragOffset.width + currentDragOffset.height * currentDragOffset.height)
        
        guard horizontalDistance >= 30 || swipeMagnitude >= minSwipeThreshold else {
            animateWrongAnswer()
            return
        }
        
        // Calculate the CENTER of the flashcard after the drag
        let cardCenterX = geo.size.width / 2 + currentDragOffset.width
        
        var selectedAnswer: Int?
        
        // More lenient approach - check horizontal position if:
        // 1. Any upward movement at all, OR
        // 2. Significant horizontal movement even without much upward movement
        if currentDragOffset.height <= minUpwardMovement || horizontalDistance >= 60 {
            selectedAnswer = getAnswerUnderCardCenter(cardCenterX: cardCenterX, geo: geo)
        }
        
        guard let selectedValue = selectedAnswer else {
            animateWrongAnswer()
            return
        }
        
        if game.checkAnswer(selected: selectedValue) {
            animateCorrectAnswer(dragOffset: currentDragOffset, geoSize: geoSize)
            flash(correct: true, selectedAnswer: selectedValue)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
        withAnimation(.easeOut(duration: 0.7)) {
            // Move the card offscreen
        }
        
        // Slightly delay and animate the scaling/opacity for better effect
        withAnimation(.easeInOut(duration: 0.6).delay(0.1)) {
            cardScale = 0.4
        }
        
        withAnimation(.easeOut(duration: 0.7).delay(0.1)) {
            cardOpacity = 0.0
        }
    }
    
    private func animateWrongAnswer() {
        // Bounce back to center
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
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
        // Reset game state immediately to prevent flash
        game.gameOver = 0
        game.isGameActive = false
        game.totalScore = 0
        game.correctAttempts = 0
        game.incorrectAttempts = 0
        game.currentStreak = 0
        
        showEndGameOverlay = false
        hasStartedRound = false
        resetCardAnimation()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            startRound()
        }
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
            
            // Increased tolerance for easier selection, especially horizontally
            let horizontalTolerance: CGFloat = 15
            
            if cardCenterX >= (pillLeftEdge - horizontalTolerance) && cardCenterX <= (pillRightEdge + horizontalTolerance) {
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
    
    @Environment(\.sizeCategory) var sizeCategory
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                StatPill(title: "Score", value: "\(score)")
                StatPill(
                    title: "Streak",
                    value: "\(streak)",
                    emphasize: streak > 1 ? .green : nil
                )
            }
            HStack(spacing: 12) {
                StatPill(
                    title: "Correct",
                    value: "\(correct)"
                )
                StatPill(
                    title: "Incorrect",
                    value: "\(incorrect)",
                    emphasize: incorrect > 0 ? .red : nil
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
    
    @Environment(\.sizeCategory) var sizeCategory
    
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
                .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
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
        case .green: return Color.mySunColor.opacity(0.6) //Color.green.opacity(0.35)
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
