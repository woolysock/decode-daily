//
//  FlashdanceSwipeHintOverlay.swift
//  DecodeDailyiOS
//
//  Created by Megan Donahue on 9/17/25.
//

import SwiftUI


// MARK: - Flashdance Swipe Hint Overlay
struct FlashdanceSwipeHintOverlay: View {
    @Binding var isVisible: Bool
    let onSwipeDetected: () -> Void
    
    @State private var animationOffset: CGSize = .zero
    @State private var animationOpacity: Double = 1.0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture {
                    // Allow dismissing by tapping outside
                    isVisible = false
                }
            
            VStack(spacing: 30) {
                Text("Swipe the card toward the correct answer!")
                    .font(.custom("LuloOne", size: 18))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // Mock game setup with answer pills and flashcard
                VStack(spacing: 20) {
                    // Answer pills at top
                    HStack(spacing: 10) {
                        MockAnswerPill(value: "15", isCorrect: false)
                        MockAnswerPill(value: "21", isCorrect: true)
                        MockAnswerPill(value: "18", isCorrect: false)
                    }
                    
                    Spacer().frame(height: 10)
                    
                    // Flashcard with animated swipe
                    ZStack {
                        // Mock flashcard
                        Text("7 × 3")
                            .font(.custom("LuloOne-Bold", size: 32))
                            .foregroundColor(.black)
                            .frame(width: 160, height: 180)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.myAccentColor1, lineWidth: 4)
                            )
                            .shadow(radius: 6)
                            .offset(animationOffset)
                            .opacity(animationOpacity)
                            .scaleEffect(pulseScale)
                        
                        // Swipe gesture indicator (hand and arrow)
                        VStack {
                            HStack(spacing: 8) {
                                Image(systemName: "hand.point.up.left.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.yellow)
                                
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 16))
                                    .foregroundColor(.yellow)
                                    .opacity(animationOpacity)
                                    .offset(x: animationOffset.width * 0.3, y: animationOffset.height * 0.3)
                            }
                            .offset(y: 120)
                        }
                    }
                }
                .frame(height: 300)
                
                Text(" ")
                    .font(.custom("LuloOne", size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                // Skip button
                Button("Got it!") {
                    onSwipeDetected()
                    isVisible = false
                }
                .font(.custom("LuloOne", size: 14))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color.myAccentColor2)
                .cornerRadius(8)
                .padding(.top, 10)
            }
            .padding(40)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Check if user swiped toward the correct area (up and slightly right)
                        if value.translation.height < -30 && abs(value.translation.width) < 80 {
                            onSwipeDetected()
                            isVisible = false
                        }
                    }
            )
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Animate the card moving toward the correct answer
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            animationOffset = CGSize(width: 20, height: -40)
            animationOpacity = 0.8
        }
        
        // Add a subtle pulse to draw attention
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.05
        }
    }
}

// Helper view for mock answer pills
private struct MockAnswerPill: View {
    let value: String
    let isCorrect: Bool
    
    var body: some View {
        Text(value)
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 80, height: 45)
            .background(isCorrect ? Color.myAccentColor2.opacity(0.6) : Color.myAccentColor1.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.2), lineWidth: 2))
            .shadow(radius: 3)
    }
}

// MARK: - Integration Instructions for FlashdanceGameView
/*
Add these to your FlashdanceGameView:

1. State variable:
@State private var showSwipeHint = false

2. Method to check for swipe hint:
private func checkForSwipeHint() {
    let hasSeenSwipeHint = UserDefaults.standard.bool(forKey: "hasSeenSwipeHint_flashdance")
    print("🎯 checkForSwipeHint called:")
    print("   - hasSeenSwipeHint: \(hasSeenSwipeHint)")
    print("   - game.isGameActive: \(game.isGameActive)")
    print("   - showHowToPlay: \(showHowToPlay)")
    
    if !hasSeenSwipeHint && game.isGameActive && !showHowToPlay {
        print("   - ✅ Conditions met, showing swipe hint in 2 seconds")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            print("   - 🎯 Actually showing swipe hint now")
            showSwipeHint = true
        }
    } else {
        print("   - ❌ Conditions not met")
    }
}

3. Add onChange handler:
.onChange(of: game.isGameActive) { oldValue, newValue in
    print("🎮 game.isGameActive changed: \(oldValue) -> \(newValue)")
    if newValue && !oldValue {
        checkForSwipeHint()
    }
}

4. Add overlay to your main ZStack (after existing overlays):
if showSwipeHint {
    FlashdanceSwipeHintOverlay(isVisible: $showSwipeHint) {
        UserDefaults.standard.set(true, forKey: "hasSeenSwipeHint_flashdance")
        print("📱 User completed swipe tutorial")
    }
    .transition(.opacity)
    .zIndex(102) // Higher than other overlays
}
*/
