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
    let onNavigateToArchive: () -> Void
    
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
//                    Text("Congrats!")
//                        .font(.custom("LuloOne-Bold", size: 24))
//                        .foregroundColor(.white)
                    
                    Image(systemName: "rectangle.and.pencil.and.ellipsis")
                        .foregroundColor(.white)
                        .font(.system(size: 40))
                    
                    Spacer().frame(height:2)
                    
                    Text("You've already seen\nthe code for")
                        .font(.custom("LuloOne", size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Text(formattedDate)
                        .font(.custom("LuloOne-Bold", size: 20))
                        .foregroundColor(.white)
                    
//                    Text("code")
//                        .font(.custom("LuloOne-Bold", size: 14))
//                        .foregroundColor(.white.opacity(0.8))
                }
                
                Divider()
                    .background(.white)
                    .padding(.horizontal, 40)
                
                // Options
                VStack(spacing: 15) {
                    
                    Text("Replay the same code?\n(Only first scores are saved)")
                        .font(.custom("LuloOne", size: 12))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        onPlayWithoutScore()
                        isVisible = false
                    }) {
                        Text("Replay")
                            .font(.custom("LuloOne-Bold", size: 16))
                            .foregroundColor(Color.myAccentColor2)
                            .frame(width: 250, height: 45)
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                    .padding(5)
                    
                    Button(action: {
                        onPlayRandom()
                        isVisible = false
                    }) {
                        Text("Pratice!")
                            .font(.custom("LuloOne-Bold", size: 16))
                            .foregroundColor(.white)
                            .frame(width: 250, height: 40)
                            .background(Color.mySunColor.opacity(0.9))
                            .contentShape(Rectangle())
                            .cornerRadius(8)
                    }
                    
                    Text("Practice rounds generate random color codes and\nare not scored.")
                        .font(.custom("LuloOne", size: 12))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    
                    Divider()
                        .background(.white)
                        .padding(.horizontal, 30)
                    
                    Text("You can also play codes from the Archive & keep earning high scores!")
                        .font(.custom("LuloOne", size: 12))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    NavigationLink(destination: MainMenuView(initialPage: 1, selectedGame: "decode")) {
                        Text("EXIT & PICK NEW DATE")
                            .font(.custom("LuloOne-Bold", size: 14))
                            .foregroundColor(.white)
                            .frame(width: 250, height: 40)
                            .background(Color.myAccentColor2)
                            .contentShape(Rectangle())
                            .cornerRadius(8)
                    }
                    
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
