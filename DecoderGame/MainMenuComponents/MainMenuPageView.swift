//
//  MainMenuPageView.swift
//  Decode! Daily iOS
//
//  Created by Assistant on 9/15/25.
//

import SwiftUI

struct MainMenuPageView: View {
    @Environment(\.sizeCategory) var sizeCategory
    @EnvironmentObject var scoreManager: GameScoreManager
    @Binding var navigateToGame: String?
    let hasUserSwiped: Bool
    
    // State for tracking button interactions with 3D tilt
    @State private var gameButtonTilts: [String: (x: Double, y: Double)] = [:]
    @State private var gameButtonPressed: [String: Bool] = [:]
    @State private var highScoreTilt: (x: Double, y: Double) = (0, 0)
    @State private var highScorePressed: Bool = false
    
    let screenHeight = UIScreen.main.bounds.height
    let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    LinearGradient.mainmenuViewGradient.ignoresSafeArea()
                    FancyAnimationLayer()
                    
                    ScrollView(.vertical) {
                        VStack(spacing: 15) {
                            
                            Spacer()
                                .frame(height: sizeCategory > .medium ? 40 : 60)
                            
                            // Game title header
                            VStack(spacing: 5) {
                                Text(" DECODE!")
                                    .font(.custom("LuloOne-Bold", size: sizeCategory > .medium ? 46 : 52))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(sizeCategory > .medium ? 0.7 : 1.0)
                                    .allowsTightening(true)
                                Text("DAILY")
                                    .font(.custom("LuloOne-Bold", size: 24))
                                    .foregroundColor(.white)
                                    .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                    .lineLimit(1)
                                    .allowsTightening(true)
                                Spacer()
                                    .frame(height: 3)
                                
                                Text("fun games, clean & simple\n+ new challenges every day!")
                                    .font(.custom("LuloOne", size: 10))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                    .allowsTightening(true)
                            }
                            .padding(.horizontal, 20)
                            
                            Spacer()
                                .frame(height: 1)
                            
                            ForEach(GameInfo.availableGames.filter { $0.isAvailable }, id: \.id) { gameInfo in
                                tiltableGameButton(for: gameInfo)
                            }
                            
                            Spacer()
                                .frame(height: 1)
                            
                            // High Scores button with tilt effect
                            tiltableHighScoreButton
                            
                            Spacer()
                                .frame(height: 1)
                            
                            HStack {
                                Image(systemName: "hand.draw")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                Text("Swipe to view archive & settings")
                                    .font(.custom("LuloOne", size: 9))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                    .lineLimit(1)
                                    .allowsTightening(true)
                            }
                            .padding(.horizontal, 50)
                            .opacity(hasUserSwiped ? 0 : 1)
                            .animation(.easeOut(duration: 0.5), value: hasUserSwiped)
                            
                            Spacer()
                        }
                    }
                    .frame(alignment: .center)
                }
            }
        }
    }
    
    @ViewBuilder
    private func tiltableGameButton(for gameInfo: GameInfo) -> some View {
        let buttonWidth = screenWidth - (sizeCategory > .medium ? 100 : 120)
        let buttonHeight: CGFloat = sizeCategory > .medium ? 75 : 65
        let tilt = gameButtonTilts[gameInfo.id] ?? (0, 0)
        let isPressed = gameButtonPressed[gameInfo.id] ?? false
        let checkDate = Calendar.current.startOfDay(for: Date())
        let isCompleted = scoreManager.isGameCompleted(gameId: gameInfo.id, date: checkDate)
        
        Button(action: {
            navigateToGame = gameInfo.id
        }) {
            HStack(alignment: .center) {
                Spacer()
                    .frame(width: 1)
                
                gameInfo.gameIcon.font(.system(size: 26))
                    .frame(maxWidth: 50)
                
                Spacer()
                    .frame(width: 5)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(gameInfo.displayName)
                        .font(.custom("LuloOne-Bold", size: 20))
                        .minimumScaleFactor(sizeCategory > .medium ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                    
                    Text(gameInfo.description)
                        .font(.custom("LuloOne", size: 10))
                        .minimumScaleFactor(sizeCategory > .medium ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                        .multilineTextAlignment(.leading)
                    
                }
                Spacer()
            }
            .frame(width: buttonWidth, height: buttonHeight)
            .frame(alignment: .leading)
            .padding(sizeCategory > .medium ? 5 : 10)
            .background(Color.mainMenuGameButtonBg)
            .foregroundColor(Color.mainMenuGameButtonFg)
            .overlay(
                Rectangle().stroke(Color.mainMenuGameButtonSt, lineWidth: 0.5)
            )
            .shadow(color: .black, radius: 3)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .rotation3DEffect(
                .degrees(tilt.x),
                axis: (x: 1, y: 0, z: 0)
            )
            .rotation3DEffect(
                .degrees(tilt.y),
                axis: (x: 0, y: 1, z: 0)
            )
            .animation(.easeOut(duration: 0.1), value: tilt.x)
            .animation(.easeOut(duration: 0.1), value: tilt.y)
            .animation(.easeOut(duration: 0.1), value: isPressed)
        }
        .disabled(!gameInfo.isAvailable)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    gameButtonPressed[gameInfo.id] = true
                    gameButtonTilts[gameInfo.id] = calculateTilt(dragValue: value, buttonWidth: buttonWidth, buttonHeight: buttonHeight)
                }
                .onEnded { _ in
                    gameButtonPressed[gameInfo.id] = false
                    withAnimation(.easeOut(duration: 0.3)) {
                        gameButtonTilts[gameInfo.id] = (0, 0)
                    }
                }
        )
        .overlay(
            // Checkmark overlay for completed games
            Group {
                if isCompleted {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.myCheckmarks)
                        .offset(x: (buttonWidth/2)-10, y: (-buttonHeight/2)+10)
                }
            }
        )
    }
    
    @ViewBuilder
    private var tiltableHighScoreButton: some View {
        let buttonWidth = screenWidth - 120
        let buttonHeight: CGFloat = 60 + 32 // Including padding
        
        // Determine the most recently played game
        let mostRecentGameId = getMostRecentlyPlayedGame()
        
        NavigationLink(destination: MultiGameLeaderboardView(selectedGameID: mostRecentGameId)) {
            VStack(spacing: 5) {
                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    Image(systemName: "trophy")
                        .font(.system(size: 10))
                    
                    Text("High Scores")
                        .font(.custom("LuloOne-Bold", size: 14))
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                }
                Text("How did you do?")
                    .font(.custom("LuloOne", size: 10))
                    .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                    .lineLimit(1)
                    .allowsTightening(true)
            }
            .padding()
            .fixedSize()
            .frame(width: buttonWidth, height: 60)
            .background(Color.myAccentColor1.opacity(0.9))
            .foregroundColor(Color.white)
            .cornerRadius(10)
            .scaleEffect(highScorePressed ? 0.98 : 1.0)
            .rotation3DEffect(
                .degrees(highScoreTilt.x),
                axis: (x: 1, y: 0, z: 0)
            )
            .rotation3DEffect(
                .degrees(highScoreTilt.y),
                axis: (x: 0, y: 1, z: 0)
            )
            .animation(.easeOut(duration: 0.1), value: highScoreTilt.x)
            .animation(.easeOut(duration: 0.1), value: highScoreTilt.y)
            .animation(.easeOut(duration: 0.1), value: highScorePressed)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    highScorePressed = true
                    highScoreTilt = calculateTilt(dragValue: value, buttonWidth: buttonWidth, buttonHeight: buttonHeight)
                }
                .onEnded { _ in
                    highScorePressed = false
                    withAnimation(.easeOut(duration: 0.3)) {
                        highScoreTilt = (0, 0)
                    }
                }
        )
    }
    
    private func getMostRecentlyPlayedGame() -> String? {
        let sortedScores = scoreManager.allScores.sorted { $0.date > $1.date }
        let recentScore = sortedScores.first
        let gameId = recentScore?.gameId ?? "decode"
        return gameId
    }
}
