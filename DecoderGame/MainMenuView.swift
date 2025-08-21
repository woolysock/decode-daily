//
//  MainMenuView.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/14/25.
//

import SwiftUI

extension Color {
    static let myAccentColor1 = Color(red:88/255,green:93/255,blue:123/255)
    static let myAccentColor2 = Color(red:49/255,green:52/255,blue:66/255)
}

struct MainMenuView: View {
    
    @EnvironmentObject var scoreManager: GameScoreManager
    
    let screenHeight = UIScreen.main.bounds.height
    let screenWidth = UIScreen.main.bounds.width
    var logoPadding: CGFloat = -25
    
    // State for tracking button interactions with 3D tilt
    @State private var gameButtonTilts: [String: (x: Double, y: Double)] = [:]
    @State private var gameButtonPressed: [String: Bool] = [:]
    @State private var highScoreTilt: (x: Double, y: Double) = (0, 0)
    @State private var highScorePressed: Bool = false
    @State private var settingsTilt: (x: Double, y: Double) = (0, 0)
    @State private var settingsPressed: Bool = false
    
    // Helper function to determine which game view to show
    @ViewBuilder
    private func gameDestination(for gameId: String) -> some View {
        switch gameId {
        case "decode":
            DecodeGameView().environmentObject(scoreManager)
        case "numbers":
            NumbersGameView().environmentObject(scoreManager)
        case "flashdance":
            FlashdanceGameView().environmentObject(scoreManager)
        case "anagrams":
            AnagramsGameView().environmentObject(scoreManager)
        default:
            EmptyView()
        }
    }
    
        
    // Helper function to calculate 3D tilt based on drag position
    private func calculateTilt(dragValue: DragGesture.Value, buttonWidth: CGFloat, buttonHeight: CGFloat) -> (x: Double, y: Double) {
        let maxTilt: Double = 3.0 // Much more subtle tilt in degrees
        
        // Calculate relative position from center (-1 to 1)
        let relativeX = (dragValue.location.x - (buttonWidth / 2)) / (buttonWidth / 2)
        let relativeY = (dragValue.location.y - (buttonHeight / 2)) / (buttonHeight / 2)
        
        // Convert to tilt angles
        // Y-axis rotation for left/right tilt (finger left = tilt left)
        let yTilt = min(max(relativeX * maxTilt, -maxTilt), maxTilt)
        // X-axis rotation for up/down tilt (finger up = tilt back)
        let xTilt = min(max(-relativeY * maxTilt, -maxTilt), maxTilt)
        
        return (x: xTilt, y: yTilt)
    }
    
    // Tiltable button for games
    @ViewBuilder
    private func tiltableGameButton(for gameInfo: GameInfo) -> some View {
        let buttonWidth = screenWidth - 120
        let buttonHeight: CGFloat = 40 + 32 // Including padding
        let tilt = gameButtonTilts[gameInfo.id] ?? (0, 0)
        let isPressed = gameButtonPressed[gameInfo.id] ?? false
        
        NavigationLink(destination: gameDestination(for: gameInfo.id)) {
            VStack(spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    gameInfo.gameIcon.font(.system(size: 14))
                    
                    Text(gameInfo.displayName)
                        .font(.custom("LuloOne-Bold", size: 22))
                }
                
                Text(gameInfo.description)
                    .font(.custom("LuloOne", size: 10))
            }
            .fixedSize()
            .frame(width: buttonWidth, height: 40)
            .padding()
            .background(Color.white)
            .foregroundColor(Color.black)
            .scaleEffect(isPressed ? 0.98 : 1.0)
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
    }
    
    // Tiltable button for High Scores
    @ViewBuilder
    private var tiltableHighScoreButton: some View {
        let buttonWidth = screenWidth - 120
        let buttonHeight: CGFloat = 60 + 32 // Including padding
        
        NavigationLink(destination: MultiGameLeaderboardView()) {
            VStack(spacing: 5) {
                HStack(spacing: 10) {
                    Image(systemName: "trophy")
                        .font(.system(size: 10))
                    
                    Text("High Scores")
                        .font(.custom("LuloOne-Bold", size: 14))
                }
                Text("How did you do?")
                    .font(.custom("LuloOne", size: 10))
            }
            .padding()
            .fixedSize()
            .frame(width: buttonWidth, height: 60)
            .background(Color.myAccentColor1)
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
    
    // Tiltable button for Settings
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
                }
                
                Text("get help, reset the app, etc.")
                    .font(.custom("LuloOne", size: 10))
            }
            .padding()
            .fixedSize()
            .frame(width: buttonWidth, height: 60)
            .background(Color.myAccentColor2)
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                GeometryReader { geo in
                    VStack(spacing: 25) {
                        Spacer()
                            .frame(height : 40)
                        //game title header
                        VStack (spacing: 5){
                            Text(" DECODE!")
                                .font(.custom("LuloOne-Bold", size: 52))
                                .foregroundColor(.white)
                            Text("DAILY")
                                .font(.custom("LuloOne-Bold", size: 24))
                                .foregroundColor(.white)
                            Text("Just Puzzles. No Distractions.")
                                .font(.custom("LuloOne", size: 10))
                                .foregroundColor(.white)
                        }
                        .fixedSize()
                        .frame(width: (screenWidth))
                        
                        Spacer()
                            .frame(height: 10)
                    
                        // Dynamic game buttons from GameInfo array with tilt effect
                        ForEach(GameInfo.availableGames.filter { $0.isAvailable }, id: \.id) { gameInfo in
                            tiltableGameButton(for: gameInfo)
                        }
                      
                        Spacer()
                            .frame(height: 5)
                        
                        // High Scores button with tilt effect
                        tiltableHighScoreButton
                        
                        // Settings button with tilt effect
                        tiltableSettingsButton
                        
                        Spacer()
                            .frame(height:40)
                    }
                }
            }
        }
        .navigationTitle("return to the main menu")
        .tint(Color.myAccentColor1)
    }
}
