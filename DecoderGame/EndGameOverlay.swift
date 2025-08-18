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
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
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
                        onPlayAgain()
                    }
                    .font(.custom("LuloOne-Bold", size: 18))
                    .foregroundColor(.black)
                    .frame(width: 200, height: 50)
                    .background(Color.white)
                    .cornerRadius(10)
                    
                    HStack(spacing: 20) {
                        Button("High Scores") {
                            onHighScores()
                            dismiss()
                        }
                        .font(.custom("LuloOne", size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.myAccentColor1)
                        .cornerRadius(8)
                        
                        Button("Main Menu") {
                            onMenu()
                            dismiss()
                        }
                        .font(.custom("LuloOne", size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.myAccentColor2)
                        .cornerRadius(8)
                    }
                }
                
//                // Tap to dismiss hint
//                Text("Tap anywhere to dismiss")
//                    .font(.custom("LuloOne", size: 10))
//                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(30)
            .background(Color.black)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 40)
        }
        .animation(.easeInOut(duration: 0.3), value: isVisible)
    }
    
    private func dismiss() {
        isVisible = false
        // Auto-start new game after dismissal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onPlayAgain()
        }
    }
}
