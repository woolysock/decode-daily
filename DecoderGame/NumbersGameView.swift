//
//  NumbersGameView.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/14/25.
//


import SwiftUI

struct NumbersGameView: View {
    @ObservedObject var game = NumbersGame()
    
    @State private var showHowToPlay = false
    
    // Instructions specific to Numbers
    private let instructionsText = """
    Numbers is ...
    
    You’ll be shown ...
    
    The more you do, the higher you score!
    
    
    { Restart any time by tapping the game title. }
    """
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 15) {
                // Title + How To Play button
                HStack {
                    Text("numbers")
                        .foregroundColor(.white)
                        .font(.custom("LuloOne-Bold", size: 20))
                        .onTapGesture {
                            game.startGame()
                        }
                    
                    Spacer()
                    
                    Button(action: {
                        showHowToPlay = true
                    }) {
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
                
                // Placeholder content area
                Text("Game content will go here")
                    .foregroundColor(.gray)
                    .font(.custom("LuloOne", size: 14))
                
                Spacer()
            }
            
            // Overlay
            if showHowToPlay {
                HowToPlayOverlay(
                    gameID: "numbers",
                    instructions: instructionsText,
                    isVisible: $showHowToPlay
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            // Auto-show the first time unless "Don't show again" is checked
            if !UserDefaults.standard.bool(forKey: "hasSeenHowToPlay_numbers") {
                withAnimation {
                    showHowToPlay = true
                }
            }
        }
    }
}
