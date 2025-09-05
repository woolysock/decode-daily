//
//  AlreadyPlayedOverlay.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 9/4/25.
//


// MARK: - AlreadyPlayedOverlay.swift
import SwiftUI

struct AlreadyPlayedOverlay: View {
    let targetDate: Date
    @Binding var isVisible: Bool
    let onPlayWithoutScore: () -> Void
    let onPlayRandom: () -> Void
    let onChooseOtherDate: () -> Void
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: targetDate)
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Rectangle()
                .fill(Color.black.opacity(0.8))
                .ignoresSafeArea()
            
            // Main content card
            VStack(spacing: 15) {
                // Header
                VStack(spacing: 10) {
                    Text("Play Again?")
                        .font(.custom("LuloOne-Bold", size: 24))
                        .foregroundColor(.white)
                    
                    Spacer().frame(height:2)
                    
                    Text("You've seen the code for")
                        .font(.custom("LuloOne-Bold", size: 14))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(formattedDate)
                        .font(.custom("LuloOne-Bold", size: 18))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Divider()
                    .background(.white)
                    .padding(.horizontal, 40)
                
                // Options
                VStack(spacing: 15) {
                    
                    Text("Play the code again?\n(Won't save your score)")
                        .font(.custom("LuloOne", size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    Button("Play again") {
                        onPlayWithoutScore()
                        isVisible = false
                    }
                    .font(.custom("LuloOne-Bold", size: 16))
                    .foregroundColor(Color.myAccentColor2)
                    .frame(width: 250, height: 45)
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(5)
                    
                    Divider()
                        .background(.white)
                        .padding(.horizontal, 30)
                    
                    Text("Or play past codes from the Archive?")
                        .font(.custom("LuloOne", size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    Button("Choose another date") {
                        onChooseOtherDate()
                        isVisible = false
                    }
                    .font(.custom("LuloOne-Bold", size: 14))
                    .foregroundColor(.white)
                    .frame(width: 250, height: 40)
                    .background(Color.myAccentColor2)
                    .cornerRadius(8)
                    
                    Divider()
                        .background(.white)
                        .padding(.horizontal, 30)
                    
                    Text("Practice with a random code? (Won't save your score)")
                        .font(.custom("LuloOne", size: 12))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    Button("Try a random code!") {
                        onPlayRandom()
                        isVisible = false
                    }
                    .font(.custom("LuloOne-Bold", size: 14))
                    .foregroundColor(.white)
                    .frame(width: 250, height: 40)
                    .background(Color.mySunColor.opacity(0.7))
                    .cornerRadius(8)
                                       
                    
                }
            }
            .padding(30)
            .background(Color.myOverlaysColor)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white, lineWidth: 1)
            )
            .padding(.horizontal, 40)
        }
    }
}
