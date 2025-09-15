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
    @Environment(\.sizeCategory) var sizeCategory
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
        
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
                        .foregroundColor(Color.mySunColor)
                        .font(.system(size: 40))
                    
                    Spacer().frame(height:2)
                    
                    Text("You've played\nthe code for")
                        .font(.custom("LuloOne", size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(2)
                        .allowsTightening(true)
                    
                    Text(formattedDate)
                        .font(.custom("LuloOne-Bold", size: 20))
                        .foregroundColor(.white)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                    
//                    Text("code")
//                        .font(.custom("LuloOne-Bold", size: 14))
//                        .foregroundColor(.white.opacity(0.8))
                }
                
                Divider()
                    .background(.white)
                    .padding(.horizontal, 40)
                
                // Options
                VStack(spacing: 15) {
                    
                    Text("This game only saves the first score per day.\n\nReplay the code anyway? (Score won't be saved)")
                        .font(.custom("LuloOne", size: 12))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(6)
                        .allowsTightening(true)
                    
                    Button(action: {
                        onPlayWithoutScore()
                        isVisible = false
                    }) {
                        Text("Replay ↺")
                            .font(.custom("LuloOne-Bold", size: 16))
                            .foregroundColor(Color.myAccentColor2)
                            .frame(width: 250, height: 45)
                            .background(Color.white)
                            .cornerRadius(10)
                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                            .lineLimit(1)
                            .allowsTightening(true)
                    }
                    .padding(5)
                    
//                    Button(action: {
//                        onPlayRandom()
//                        isVisible = false
//                    }) {
//                        Text("Pratice!")
//                            .font(.custom("LuloOne-Bold", size: 16))
//                            .foregroundColor(.white)
//                            .frame(width: 250, height: 40)
//                            .background(Color.mySunColor.opacity(0.9))
//                            .contentShape(Rectangle())
//                            .cornerRadius(8)
//                    }
//                    
//                    Text("Practice rounds generate random color codes and\nare not scored.")
//                        .font(.custom("LuloOne", size: 12))
//                        .foregroundColor(.white)
//                        .multilineTextAlignment(.center)
//                    
                    
                    Divider()
                        .background(.white)
                        .padding(.horizontal, 30)
                    
                    Text("Or play past daily codes to keep earning high scores!")
                        .font(.custom("LuloOne", size: 12))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(3)
                        .allowsTightening(true)
                    
                    NavigationLink(destination: MainMenuView(initialPage: 1, selectedGame: "decode")) {
                        Text("PICK NEW DATE ✓")
                            .font(.custom("LuloOne-Bold", size: sizeCategory > .large ? 14 : 16))
                            .foregroundColor(.white)
                            .frame(width: 250, height: 45)
                            .background(Color.myAccentColor2)
                            .contentShape(Rectangle())
                            .cornerRadius(8)
                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                            .lineLimit(1)
                            .allowsTightening(true)
                    }
                    .padding(5)
                    
                }
            }
            .padding(horizontalSizeClass == .compact ? 30 : 40)
            .background(Color.myOverlaysColor)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white, lineWidth: 0.5)
            )
            .padding(.horizontal, horizontalSizeClass == .compact ? 30 : 40)
        }
    }
        
    
}
