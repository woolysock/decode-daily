//
//  EndGameOverlay.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/17/25.
//

import SwiftUI

struct EndGameOverlay: View {
    
    @Environment(\.sizeCategory) var sizeCategory
    
    let gameID: String
    let finalScore: Int
    let displayName: String
    @Binding var isVisible: Bool
    let onPlayAgain: () -> Void
    let onHighScores: () -> Void
    let onMenu: () -> Void
    
    // Optional parameters for different score displays
    let timeElapsed: TimeInterval?
    let additionalInfo: String?
    
    // NEW: Optional GameScore for additional properties
    let gameScore: GameScore?
    
    // Button activation delay
    @State private var buttonsAreActive: Bool = false
    
    // Animation states
    @State private var showCelebration: Bool = false
    @State private var animationPhase: Double = 0
    
    // Original init (backwards compatible)
    init(
        gameID: String,
        finalScore: Int,
        displayName: String,
        isVisible: Binding<Bool>,
        onPlayAgain: @escaping () -> Void,
        onHighScores: @escaping () -> Void,
        onMenu: @escaping () -> Void,
        timeElapsed: TimeInterval? = nil,
        additionalInfo: String? = nil
    ) {
        self.gameID = gameID
        self.finalScore = finalScore
        self.displayName = displayName
        self._isVisible = isVisible
        self.onPlayAgain = onPlayAgain
        self.onHighScores = onHighScores
        self.onMenu = onMenu
        self.timeElapsed = timeElapsed
        self.additionalInfo = additionalInfo
        self.gameScore = nil
    }
    
    // NEW: Init with GameScore
    init(
        gameID: String,
        finalScore: Int,
        displayName: String,
        isVisible: Binding<Bool>,
        onPlayAgain: @escaping () -> Void,
        onHighScores: @escaping () -> Void,
        onMenu: @escaping () -> Void,
        timeElapsed: TimeInterval? = nil,
        additionalInfo: String? = nil,
        gameScore: GameScore? = nil
    ) {
        self.gameID = gameID
        self.finalScore = finalScore
        self.displayName = displayName
        self._isVisible = isVisible
        self.onPlayAgain = onPlayAgain
        self.onHighScores = onHighScores
        self.onMenu = onMenu
        self.timeElapsed = timeElapsed
        self.additionalInfo = additionalInfo
        self.gameScore = gameScore
    }
    
    
    private var scoreText: String {
        switch gameID {
        case "anagrams":
            return "final score"
        case "decode":
            return "score"
        case "numbers":
            return "score"
        case "flashdance":
            return "final score"
        default:
            return "Score"
        }
    }
    
    // NEW: Computed property for additional score details
    private var additionalScoreDetails: String? {
        //print("🔍 EndGameOverlay score = \(String(describing: gameScore))")
        //print("🔍 DEBUG: gameID = \(gameID)")
        
        guard let gameScore = gameScore else {
            return nil
        }
        
        switch gameID {
        case "decode":
            //print("🔍 DEBUG: In decode case")
            guard let decodeProps = gameScore.decodeProperties else {
                //print("🔍 DEBUG: decodeProps is nil")
                return nil
            }
            let formattedTime = formatDuration(decodeProps.gameDuration)
            return "Turns: \(decodeProps.turnsToSolve)/7\nTime: \(formattedTime)"
            
        case "flashdance":
            guard let flashProps = gameScore.flashdanceProperties else { return nil }
            return "Correct: \(flashProps.correctAnswers)\nWrong: \(flashProps.incorrectAnswers)\nBest Streak: \(flashProps.longestStreak)"
            
        case "anagrams":
            guard let theseProps = gameScore.anagramsProperties else { return nil }
            return "\(theseProps.wordsCompleted) words solved\n\n\(theseProps.skippedWords) skipped words\nout of \(theseProps.totalWordsInSet)\n\nlongest word solved:\n\(theseProps.longestWord) letters"
            
        default:
            //print("🔍 DEBUG: In default case")
            return "Good Job!"
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Rectangle()
                .fill(Color.black.opacity(0.8))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Celebration animation layer - simplified version
            if showCelebration {
                CelebrationAnimationView()
                    .allowsHitTesting(false)
            }
            
            // Main content card
            VStack(spacing: 25) {
                Spacer()
                    .frame(height: 1)
                // Header
                VStack(spacing: 10) {
                    Text("Game Over!")
                        .font(.custom("LuloOne-Bold", size: 28))
                        .foregroundColor(.white)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(2)
                        .allowsTightening(true)
                        .multilineTextAlignment(.center)
                    
                    Text(displayName)
                        .font(.custom("LuloOne", size: 18))
                        .foregroundColor(.white.opacity(0.8))
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                }
                
                Divider()
                    .background(.white)
                    .padding(.horizontal, sizeCategory > .large ? 30 : 40)
                
                // Score section
                VStack(spacing: 15) {
                    VStack(spacing: 7) {
                        Text(scoreText)
                            .font(.custom("LuloOne", size: 16))
                            .foregroundColor(.white.opacity(0.8))
                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                            .lineLimit(4)
                            .allowsTightening(true)
                        
                        Text("\(finalScore)")
                            .font(.custom("LuloOne-Bold", size: 48))
                            .foregroundColor(.white)
                            .monospacedDigit()
                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                            .lineLimit(1)
                            .allowsTightening(true)
                        
                        // NEW: Additional score details
                        if let details = additionalScoreDetails {
                            Text(details)
                                .font(.custom("LuloOne", size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.top, 6)
                                .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                .allowsTightening(true)
                        }
                        else {
                            Text("Score not saved\n(code was seen before)")
                                .font(.custom("LuloOne", size: 12))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.top, 6)
                                .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                .allowsTightening(true)
                        }
                        //                        Text("★ ★ ★")
                        //                            .font(.custom("LuloOne", size: 16))
                        //                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Divider()
                    .background(.white)
                    .padding(.horizontal, 40)
                
                // Action buttons
                VStack(spacing: 15) {
                    
                    if gameID == "decode" {
                        NavigationLink(destination: MainMenuView(initialPage: 1, selectedGame: "decode")) {
                            Text("New Code?")
                                .font(.custom("LuloOne-Bold", size: 18))
                                .frame(width: 250, height: 60)
                                .foregroundColor(buttonsAreActive ? .black : .white.opacity(0.4))
                                .background(buttonsAreActive ? Color.white : Color.black.opacity(0.4))
                                .cornerRadius(10)
                                .disabled(!buttonsAreActive)
                                .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                .lineLimit(1)
                                .allowsTightening(true)
                                .animation(.easeInOut(duration: 0.3), value: buttonsAreActive)
                                .simultaneousGesture(
                                    TapGesture()
                                        .onEnded { _ in
                                            isVisible = false  // Dismiss the overlay
                                        }
                                )
                        }
                    } else {
                        Button("Replay?") {
                            dismiss(startNewGame: true)
                        }
                        .font(.custom("LuloOne-Bold", size: 18))
                        .foregroundColor(buttonsAreActive ? .black : .gray)
                        .frame(width: 250, height: 60)
                        .background(buttonsAreActive ? Color.white : Color.black.opacity(0.4))
                        .cornerRadius(10)
                        .disabled(!buttonsAreActive)
                        .animation(.easeInOut(duration: 0.3), value: buttonsAreActive)
                        .contentShape(Rectangle())
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                    }
                    
                    HStack(spacing: 10) {
                        NavigationLink(destination: MultiGameLeaderboardView(selectedGameID: gameID)) {
                            Text("High\nScores")
                                .font(.custom("LuloOne", size: 14))
                                .foregroundColor(buttonsAreActive ? .white : .black)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(buttonsAreActive ? Color.myAccentColor2 : Color.black.opacity(0.4))
                                .cornerRadius(8)
                                .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                .lineLimit(2)
                                .allowsTightening(true)
                                .frame(height: 60)
                                
                        }
                        .disabled(!buttonsAreActive)
                        .animation(.easeInOut(duration: 0.3), value: buttonsAreActive)
                        .simultaneousGesture(
                            TapGesture()
                                .onEnded { _ in
                                    isVisible = false  // Dismiss the overlay
                                }
                        )
                        
                        
                        NavigationLink(destination: MainMenuView(initialPage: 0)) {
                            Text("Main\nMenu")
                                .font(.custom("LuloOne", size: 14))
                                .foregroundColor(buttonsAreActive ? .white : .black)
                                .padding(.horizontal, 26)
                                .padding(.vertical, 12)
                                .background(buttonsAreActive ? Color.myAccentColor2 : Color.black.opacity(0.4))
                                .cornerRadius(8)
                                .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                .lineLimit(2)
                                .allowsTightening(true)
                                .frame(height: 60)
                        }
                        .disabled(!buttonsAreActive)
                        .animation(.easeInOut(duration: 0.3), value: buttonsAreActive)
                        .simultaneousGesture(
                            TapGesture()
                                .onEnded { _ in
                                    isVisible = false  // Dismiss the overlay
                                }
                        )
                    }
                }
            }
            .padding(sizeCategory > .large ? 20 : 40)
            .background(Color.myOverlaysColor)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white, lineWidth: 1)
                    .foregroundColor(.clear)
            )
            .opacity(1.0) // Always show the content box immediately
            .scaleEffect(1.0) // No scaling animation on the content box
        }
        .ignoresSafeArea(.all)
        .onAppear {
            startCelebrationSequence()
        }
        .onChange(of: isVisible) { oldValue, newValue in
            if newValue {
                startCelebrationSequence()
            }
        }
    }
    
    
    private func startCelebrationSequence() {
        print("Starting celebration sequence") // Debug print
        
        // Reset states
        showCelebration = false
        buttonsAreActive = false
        
        // Show the content box first (without celebration)
        // No celebration animation yet - just show the content
        
        // Start celebration sequence
        
        withAnimation {
            showCelebration = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Activate buttons at the same time
            buttonsAreActive = true
        }
    }
    
    private func dismiss(startNewGame: Bool = false) {
        isVisible = false
        if startNewGame {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onPlayAgain()
            }
        }
    }
}

// MARK: - Celebration Animation View

struct CelebrationAnimationView: View {
    @State private var showBurst = false
    @State private var burstOpacity = 0.0
    @State private var rotationBonus = 0.0
    
    var body: some View {
        ZStack {
            // Only the radial burst rays - the ones that were actually visible!
            ForEach(0..<24, id: \.self) { index in
                let angle = Double(index) * 15.0 + rotationBonus // 24 rays, 15 degrees apart
                
                Capsule()
                    .fill(index % 3 == 0 ? Color.myAccentColor1 : Color.myAccentColor2.opacity(0.7))
                    .frame(width: 10, height: showBurst ? 400 : 30) // Even longer rays
                    .offset(y: -(showBurst ? 200 : 15)) // Offset to center
                    .rotationEffect(.degrees(angle))
                    .opacity(burstOpacity)
                    .scaleEffect(showBurst ? 1.0 : 0.2, anchor: .bottom)
                //                    .animation(
                //                        .easeOut(duration: 1.0).delay(Double(index) * 0.03),
                //                        value: showBurst
                //                    )
                //                    .animation(
                //                        .easeOut(duration: 1.0).delay(1.2),
                //                        value: burstOpacity
                //                    )
            }
        }
        .onAppear {
            print("🎉 CelebrationAnimationView appeared - rays of light!")
            
            // Start the ray burst immediately
            burstOpacity = 1.0
            
            // Add slight rotation for more dynamic effect
            withAnimation(.linear(duration: 1.5)) {
                rotationBonus = 30
            }
            
            // Trigger the burst expansion
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                showBurst = true
            }
            
            // Fade out after the show
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                burstOpacity = 0.0
            }
        }
    }
}
