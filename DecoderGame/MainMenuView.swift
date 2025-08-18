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
                        
//                        // Title image exactly 15 pts below safe area
//                        Image("TitleLoader-w")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: screenWidth - 20)
//                            .padding(.top, geo.safeAreaInsets.top + 25)
//                            .frame(maxWidth: .infinity, alignment: .center)
                    
                        // Dynamic game buttons from GameInfo array
                        ForEach(GameInfo.availableGames.filter { $0.isAvailable }, id: \.id) { gameInfo in
                            NavigationLink(destination: gameDestination(for: gameInfo.id)) {
                                VStack(spacing: 5) {
                                    Text(gameInfo.displayName)
                                        .font(.custom("LuloOne-Bold", size: 22))
                                    Text(gameInfo.description)
                                        .font(.custom("LuloOne", size: 12))
                                        .opacity(0.8)
                                }
                                .fixedSize()
                                .frame(width: (screenWidth-120), height: 40)
                                .padding()
                                //.background(gameInfo.id == "decode" ? Color.white : myAccentColor1)
                                .background(Color.white)
                                //.foregroundColor(gameInfo.id == "decode" ? .black : .white)
                                .foregroundColor(Color.black)
                            }
                            .disabled(!gameInfo.isAvailable)
                        }
                        
//                        NavigationLink(destination: ArchiveView()) {
//                            Text("Archives")
//                                .fixedSize()
//                                .frame(width: (screenWidth-120), height: 40)
//                                .font(.system(size: 20, weight: .black))
//                                .padding()
//                                .background(myAccentColor1)
//                                .foregroundColor(.white)
//                        }
                        
                        Spacer()
                            .frame(height: 5)
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
                            .frame(width: (screenWidth-120), height: 60)
                            .background(Color.myAccentColor1)
                            .foregroundColor(Color.white)
                            .cornerRadius(10)
                        }
                        
                        NavigationLink(destination: SettingsView()) {
                            VStack(spacing: 5) {
                                HStack(spacing: 10) {
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
                            .frame(width: (screenWidth-120), height: 60)
                            .background(Color.myAccentColor2)
                            .foregroundColor(Color.white)
                            .cornerRadius(10)
                        }
                        
                       
                        
                        //Spacer().frame(height: screenHeight / 6)
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


//struct ArchiveView: View {
//    var body: some View {
//        ZStack {
//            Color.black.ignoresSafeArea()
//            VStack(spacing: 15) {
//                Text("Play From the Archives")
//                    .foregroundColor(.white)
//                    .font(.system(size: 20, weight: .black))
//            }
//        }
//    }
//}

//struct ScoresView: View {
//    var body: some View {
//        ZStack {
//            Color.black.ignoresSafeArea()
//            VStack(spacing: 15) {
//                Text("High Scores")
//                    .foregroundColor(.white)
//                    .font(.system(size: 20, weight: .black))
//            }
//        }
//    }
//}

//struct SettingsView: View {
//    var body: some View {
//        ZStack {
//            Color.black.ignoresSafeArea()
//            VStack(spacing: 15) {
//                Text("Your Account & Other Stuff")
//                    .foregroundColor(.white)
//                    .font(.system(size: 20, weight: .black))
//            }
//        }
//    }
//}
