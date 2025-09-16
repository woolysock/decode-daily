//
//  AccountPageView.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 9/15/25.
//


//
//  AccountPageView.swift
//  Decode! Daily iOS
//
//  Created by Assistant on 9/15/25.
//

import SwiftUI

struct AccountPageView: View {
    @Environment(\.sizeCategory) var sizeCategory
    @EnvironmentObject var scoreManager: GameScoreManager
    
    // State for tracking button interactions with 3D tilt
    @State private var settingsTilt: (x: Double, y: Double) = (0, 0)
    @State private var settingsPressed: Bool = false
    
    let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        NavigationStack {
            ScrollView {
                ZStack {
                    LinearGradient.statsViewGradient.ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Spacer()
                            .frame(height: sizeCategory > .medium ? 40 : 60)
                        
                        // Title for the second page
                        VStack(spacing: 10) {
                            Text("Stats &\nAccount")
                                .font(.custom("LuloOne-Bold", size: 40))
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                .allowsTightening(true)
                                .padding(.horizontal, 20)
                            
                            // Stats go here
                            VStack(spacing: sizeCategory > .large ? 14 : 18) {
                                // Total games played
                                statCard(
                                    title: "Games Played",
                                    value: "\(scoreManager.allScores.count)",
                                    icon: "gamecontroller"
                                )
                                
                                // Recent activity
                                statCard(
                                    title: "Recent Games",
                                    value: "\(scoreManager.getScoresFromLastWeek().count)",
                                    subtitle: "this week",
                                    icon: "calendar"
                                )
                                
                                Spacer()
                                    .frame(height: sizeCategory > .large ? 1 : 5)
                                
                                Text("High Scores")
                                    .font(.custom("LuloOne", size: 12))
                                    .foregroundColor(.white.opacity(0.8))
                                    .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                    .lineLimit(1)
                                    .allowsTightening(true)
                                
                                // Game-specific high scores
                                VStack(spacing: 10) {
                                    // Decode high score
                                    gameStatCard(
                                        gameId: "decode",
                                        gameName: "Decode",
                                        icon: "circle.hexagonpath"
                                    )
                                    
                                    // Flashdance high score
                                    gameStatCard(
                                        gameId: "flashdance",
                                        gameName: "Flashdance",
                                        icon: "bolt.circle"
                                    )
                                    
                                    // Anagrams high score
                                    gameStatCard(
                                        gameId: "anagrams",
                                        gameName: "'Grams",
                                        icon: "60.arrow.trianglehead.clockwise"
                                    )
                                }
                                .padding(.horizontal, 10)
                            }
                            .padding(.horizontal, sizeCategory > .medium ? 10 : 20)
                        }
                        
                        Divider().background(.white)
                        
                        // Settings button with tilt effect
                        tiltableSettingsButton
                        
                        Spacer()
                    }
                    .padding(.horizontal, sizeCategory > .medium ? 30 : 40)
                }
            }
        }
    }
    
    @ViewBuilder
    private func statCard(title: String, value: String, subtitle: String? = nil, icon: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color.myAccentColor1)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("LuloOne", size: sizeCategory > .medium ? 10 : 12))
                    .foregroundColor(.white)
                    .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                    .lineLimit(1)
                    .allowsTightening(true)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.custom("LuloOne", size: 8))
                        .foregroundColor(.white.opacity(0.8))
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                }
            }
            
            Spacer()
            
            Text(value)
                .font(.custom("LuloOne-Bold", size: 18))
                .foregroundColor(.white)
                .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                .lineLimit(1)
                .allowsTightening(true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(.clear)
        .cornerRadius(10)
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func gameStatCard(gameId: String, gameName: String, icon: String) -> some View {
        let gameScores = scoreManager.getScores(for: gameId)
        let highestScore = gameScores.first
        let highScore = highestScore?.finalScore ?? 0
        let gamesPlayed = gameScores.count
        
        NavigationLink(destination: MultiGameLeaderboardView(selectedGameID: gameId)) {
            HStack(spacing: 15) {
                // Game Name & Count Played on left
                VStack(alignment: .leading, spacing: 3) {
                    Text(gameName)
                        .font(.custom("LuloOne-Bold", size: 12))
                        .foregroundColor(.white)
                        .minimumScaleFactor(sizeCategory > .medium ? 0.7 : 1.0)
                        .lineLimit(2)
                        .allowsTightening(true)
                    
                    if gamesPlayed > 0 {
                        Text("\(gamesPlayed) game\(gamesPlayed == 1 ? "" : "s")")
                            .font(.custom("LuloOne", size: 10))
                            .foregroundColor(.white.opacity(0.8))
                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                            .lineLimit(1)
                            .allowsTightening(true)
                    } else {
                        Text("Not played")
                            .font(.custom("LuloOne", size: 10))
                            .foregroundColor(.white.opacity(0.8))
                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                            .lineLimit(1)
                            .allowsTightening(true)
                    }
                }
                
                Spacer()
                
                // Highest score & date achieved
                VStack(alignment: .trailing, spacing: 2) {
                    Text(gamesPlayed > 0 ? "\(highScore)" : "—")
                        .font(.custom("LuloOne-Bold", size: 16))
                        .foregroundColor(gamesPlayed > 0 ? .white : .white.opacity(0.4))
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                    
                    if gamesPlayed > 0, let score = highestScore {
                        Text(DateFormatter.day2Formatter.string(from: score.date))
                            .font(.custom("LuloOne", size: 8))
                            .foregroundColor(.white.opacity(0.8))
                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                            .lineLimit(1)
                            .allowsTightening(true)
                    } else {
                        Text("Not played")
                            .font(.custom("LuloOne", size: 10))
                            .foregroundColor(.white.opacity(0.8))
                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                            .lineLimit(1)
                            .allowsTightening(true)
                    }
                }
                .frame(maxWidth: 80)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.myAccentColor2)
            .cornerRadius(10)
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var tiltableSettingsButton: some View {
        let buttonWidth = screenWidth - 120
        let buttonHeight: CGFloat = 60 + 32 // Including padding
        
        NavigationLink(destination: SettingsView()) {
            VStack(spacing: 5) {
                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    Image(systemName: "person.text.rectangle")
                        .font(.system(size: 10))
                    
                    Text("Settings")
                        .font(.custom("LuloOne-Bold", size: 14))
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                }
                
                Text("get help, reset the app, etc.")
                    .font(.custom("LuloOne", size: sizeCategory > .large ? 8 : 10))
                    .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                    .lineLimit(1)
                    .allowsTightening(true)
            }
            .padding(10)
            .fixedSize()
            .frame(width: buttonWidth, height: 60)
            .background(Color.myAccentColor1)
            .foregroundColor(Color.white)
            .cornerRadius(10)
            .scaleEffect(settingsPressed ? 0.98 : 1.0)
            .rotation3DEffect(
                .degrees(settingsTilt.x),
                axis: (x: 1, y: 0, z: 0)
            )
            .rotation3DEffect(
                .degrees(settingsTilt.y),
                axis: (x: 0, y: 1, z: 0)
            )
            .animation(.easeOut(duration: 0.1), value: settingsTilt.x)
            .animation(.easeOut(duration: 0.1), value: settingsTilt.y)
            .animation(.easeOut(duration: 0.1), value: settingsPressed)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    settingsPressed = true
                    settingsTilt = calculateTilt(dragValue: value, buttonWidth: buttonWidth, buttonHeight: buttonHeight)
                }
                .onEnded { _ in
                    settingsPressed = false
                    withAnimation(.easeOut(duration: 0.3)) {
                        settingsTilt = (0, 0)
                    }
                }
        )
    }
}
