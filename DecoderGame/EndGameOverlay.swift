//
//  EndGameOverlay.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/17/25.
//

import SwiftUI

struct EndGameOverlay: View {
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
    
    // Button activation delay
    @State private var buttonsAreActive: Bool = false
    
    // Animation states
    @State private var showCelebration: Bool = false
    @State private var animationPhase: Double = 0
    
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
    }
    
       
    private var scoreText: String {
        switch gameID {
        case "anagrams":
            return "Words Solved"
        case "decode":
            return "Turns"
        case "numbers":
            return "Score"
        case "flashdance":
            return "Equations Solved"
        default:
            return "Score"
        }
    }
    
    
    private var timeText: String? {
        guard let time = timeElapsed else { return nil }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Rectangle()
                .fill(Color.black.opacity(0.8))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture {
                    if buttonsAreActive {
                        dismiss()
                    }
                }
            
            // Celebration animation layer - simplified version
            if showCelebration {
                CelebrationAnimationView()
                    .allowsHitTesting(false)
            }
            
            // Main content card
            VStack(spacing: 25) {
                // Header
                VStack(spacing: 10) {
                    Text("Game Over!")
                        .font(.custom("LuloOne-Bold", size: 28))
                        .foregroundColor(.white)
                    
                    Text(displayName)
                        .font(.custom("LuloOne", size: 16))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Divider()
                    .background(.white)
                    .padding(.horizontal, 40)
                
                // Score section
                VStack(spacing: 15) {
                    VStack(spacing: 5) {
                        Text(scoreText)
                            .font(.custom("LuloOne", size: 14))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("\(finalScore)")
                            .font(.custom("LuloOne-Bold", size: 48))
                            .foregroundColor(.white)
                            .monospacedDigit()
                    }
                    
                    // Time elapsed (if provided)
                    if let timeText = timeText {
                        VStack(spacing: 5) {
                            Text("Time")
                                .font(.custom("LuloOne", size: 12))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(timeText)
                                .font(.custom("LuloOne-Bold", size: 20))
                                .foregroundColor(.white)
                                .monospacedDigit()
                        }
                    }
                    
                    // Additional info (if provided)
                    if let info = additionalInfo {
                        Text(info)
                            .font(.custom("LuloOne", size: 12))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                }
                
                Divider()
                    .background(.white)
                    .padding(.horizontal, 40)
                
                // Action buttons
                VStack(spacing: 15) {
                    Button("Play Again") {
                        dismiss(startNewGame: true)
                    }
                    .font(.custom("LuloOne-Bold", size: 18))
                    .foregroundColor(buttonsAreActive ? .black : .gray)
                    .frame(width: 200, height: 50)
                    .background(buttonsAreActive ? Color.white : Color.gray.opacity(0.4))
                    .cornerRadius(10)
                    .disabled(!buttonsAreActive)
                    .animation(.easeInOut(duration: 0.3), value: buttonsAreActive)
                    
                    HStack(spacing: 20) {
                        Button("High Scores") {
                            onHighScores()
                            dismiss()
                        }
                        .font(.custom("LuloOne", size: 14))
                        .foregroundColor(buttonsAreActive ? .white : .gray)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(buttonsAreActive ? Color.myAccentColor1 : Color.gray.opacity(0.4))
                        .cornerRadius(8)
                        .disabled(!buttonsAreActive)
                        .animation(.easeInOut(duration: 0.3), value: buttonsAreActive)
                        
                        Button("Main Menu") {
                            onMenu()
                            dismiss()
                        }
                        .font(.custom("LuloOne", size: 14))
                        .foregroundColor(buttonsAreActive ? .white : .gray)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(buttonsAreActive ? Color.myAccentColor2 : Color.gray.opacity(0.4))
                        .cornerRadius(8)
                        .disabled(!buttonsAreActive)
                        .animation(.easeInOut(duration: 0.3), value: buttonsAreActive)
                    }
                }
            }
            .padding(30)
            .background(Color.black)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 40)
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
        
        // Start celebration when buttons become active (after 1 second)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("Starting celebration animation now") // Debug print
            withAnimation {
                showCelebration = true
            }
            
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
                    .fill(index % 3 == 0 ? Color.myAccentColor1 : Color.white)
                    .frame(width: 10, height: showBurst ? 400 : 30) // Even longer rays
                    .offset(y: -(showBurst ? 200 : 15)) // Offset to center
                    .rotationEffect(.degrees(angle))
                    .opacity(burstOpacity)
                    .scaleEffect(showBurst ? 1.0 : 0.2, anchor: .bottom)
                    .animation(
                        .easeOut(duration: 1.2).delay(Double(index) * 0.03),
                        value: showBurst
                    )
                    .animation(
                        .easeOut(duration: 1.8).delay(1.2),
                        value: burstOpacity
                    )
            }
        }
        .onAppear {
            print("CelebrationAnimationView appeared - rays of light only!")
            
            // Start the ray burst immediately
            burstOpacity = 1.0
            
            // Add slight rotation for more dynamic effect
            withAnimation(.linear(duration: 1.5)) {
                rotationBonus = 30
            }
            
            // Trigger the burst expansion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showBurst = true
            }
            
            // Fade out after the show
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                burstOpacity = 0.0
            }
        }
    }
}

// Star shape for celebration sparkles
struct CelebrationStar: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.4
        
        for i in 0..<10 {
            let angle = Double(i) * .pi / 5
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let x = center.x + cos(angle - .pi / 2) * radius
            let y = center.y + sin(angle - .pi / 2) * radius
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

// Star shape for sparkles
struct Star: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.4
        
        for i in 0..<10 {
            let angle = Double(i) * .pi / 5
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let x = center.x + cos(angle - .pi / 2) * radius
            let y = center.y + sin(angle - .pi / 2) * radius
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}
