//
// MultiGameLeaderboardView.swift
//

import SwiftUI
import Mixpanel

// MARK: - Single Leaderboard Page
struct LeaderboardPageView: View {
    let gameID: String
    let title: String
    let onPlayGame: () -> Void

    @EnvironmentObject var scoreManager: GameScoreManager
    @Environment(\.sizeCategory) var sizeCategory

    var body: some View {
        VStack {
            if filteredScores.isEmpty {
                NoScoresView(onPlayGame: onPlayGame)
            } else {
                VStack {
                    LeaderboardHeaderText(count: filteredScores.count)
                    
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(filteredScores) { score in
                                ScoreRowView(score: score)
                            }
                            
                            // Add play button at bottom of scores list
                            VStack(spacing: 15) {
                              
                                Spacer().frame(height:5)
                                
                                Button(action: onPlayGame) {
                                    VStack(spacing: 5) {
                                        Text("play")
                                            .font(.custom("LuloOne-Bold", size: 16))
                                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                            .lineLimit(1)
                                            .allowsTightening(true)
                                        Text(gameDisplayName.lowercased())
                                            .font(.custom("LuloOne-Bold", size: 16))
                                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                            .lineLimit(1)
                                            .allowsTightening(true)
                                    }
                                    .padding()
                                    .frame(height: 60)
                                    .frame(width: 220)
                                    .background(Color.myAccentColor2)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                Spacer().frame(height: 20)
                            }
                        }
                    }
                }
            }
        }
        .animation(.default, value: scoreManager.allScores)
    }
    
    private var gameDisplayName: String {
        if let game = GameInfo.availableGames.first(where: { $0.id.lowercased() == gameID.lowercased() }) {
            return game.displayName
        }
        return gameID.capitalized // Fallback to capitalized gameID
    }
    
    private var filteredScores: [GameScore] {
        scoreManager.allScores
            .filter { $0.gameId == gameID }
            .sorted {
                if $0.finalScore == $1.finalScore {
                    return $0.date > $1.date
                }
                return $0.finalScore > $1.finalScore
            }
    }
}

// MARK: - Subviews
struct NoScoresView: View {
    
    @Environment(\.sizeCategory) var sizeCategory
    
    let onPlayGame: () -> Void
    
    var body: some View {
        Spacer().frame(height: 20)
        VStack(spacing: 10) {
            Text("No scores yet!")
                .font(.custom("LuloOne-Bold", size: 12))
                .foregroundColor(.black)
                .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                .allowsTightening(true)
            
            Spacer().frame(height:10)
            
            Button(action: onPlayGame) {
                VStack(spacing: 5) {
                    Text("play")
                        .font(.custom("LuloOne-Bold", size: 16))
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                    Text("now")
                        .font(.custom("LuloOne-Bold", size: 16))
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                }
                .padding()
                .frame(height: 60)
                .frame(width: 220)
                .background(Color.myAccentColor2)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        Spacer()
    }
}

struct LeaderboardHeaderText: View {
    let count: Int
    @Environment(\.sizeCategory) var sizeCategory

    var body: some View {
        Text(
            count == 0
                ? "You have no high scores"
                : "You have \(count) high score\(count == 1 ? "" : "s")"
        )
        .font(.custom("LuloOne", size: 12))
        .foregroundColor(.black)
        .padding(.bottom, 5)
        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
        .lineLimit(1)
        .allowsTightening(true)
    }
}

struct ScoreRowView: View {
    
    @Environment(\.sizeCategory) var sizeCategory
    let score: GameScore

    var body: some View {
        HStack(spacing: 5) {
            Spacer()
                .frame(width: 20)
            VStack(alignment: .leading) {
                
                HStack(spacing: 4) {
                    Text("Played: \(DateFormatter.scorePlayedDisplayFormatter.string(from:score.date))")
                        .font(.custom("LuloOne-Bold", size: 12))
                        .foregroundColor(.black)
                        .minimumScaleFactor(sizeCategory > .medium ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                }
                
                // CUSTOM SCORE EXTRAS
                
                if let flashdanceProps = score.flashdanceProperties {
                    if let the_date = score.archiveDate {
                        Text("Game ID: \(DateFormatter.dayFormatter.string(from: the_date))\n")
                            .font(.custom("LuloOne", size: 10))
                            .foregroundColor(.black)
                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                            .lineLimit(1)
                            .allowsTightening(true)
                    } else {
                        Text("Game ID: Not Found\n")
                            .font(.custom("LuloOne", size: 10))
                            .foregroundColor(.black)
                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                            .lineLimit(2)
                            .allowsTightening(true)
                    }
                    
                    Text(" ☆ Equations solved: \(flashdanceProps.correctAnswers)")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.black)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(2)
                        .allowsTightening(true)
                    
                    Text(" ☆ Wrong Answers: \(flashdanceProps.incorrectAnswers)")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.black)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(2)
                        .allowsTightening(true)
                    
                    Text(" ☆ Longest Streak: \(flashdanceProps.longestStreak) in a row")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.black)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(2)
                        .allowsTightening(true)
                }
                
                if let decodeProps = score.decodeProperties {
                    if let the_date = score.archiveDate {
                        Text("Game ID: \(DateFormatter.dayFormatter.string(from: the_date))\n")
                            .font(.custom("LuloOne", size: 10))
                            .foregroundColor(.black)
                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                            .lineLimit(2)
                            .allowsTightening(true)
                    } else {
                        Text("Game ID: Not Found\n")
                            .font(.custom("LuloOne", size: 10))
                            .foregroundColor(.black)
                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                            .lineLimit(2)
                            .allowsTightening(true)
                    }
                    Text(" ☆ Guesses: \(decodeProps.turnsToSolve)")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.black)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                    
                    let duration = Int(decodeProps.gameDuration)
                    let timeText = duration < 60 ? "\(duration) sec" : String(format: "%d:%02d", duration / 60, duration % 60)
                    
                    Text(" ☆ Time to Solve: \(timeText)")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.black)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(2)
                        .allowsTightening(true)
                }
                
                if let anagramsProps = score.anagramsProperties {
                    if let the_date = score.archiveDate {
                        Text("Game ID: \(DateFormatter.dayFormatter.string(from: the_date))\n")
                            .font(.custom("LuloOne", size: 10))
                            .foregroundColor(.black)
                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                            .lineLimit(2)
                            .allowsTightening(true)
                    } else {
                        Text("Game ID: Not Found\n")
                            .font(.custom("LuloOne", size: 10))
                            .foregroundColor(.black)
                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                            .lineLimit(2)
                            .allowsTightening(true)
                    }
                    Text(" ☆ Solved: \(Int(anagramsProps.wordsCompleted)) words (of \(anagramsProps.totalWordsInSet))")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.black)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(2)
                        .allowsTightening(true)
                    Text(" ☆ Skipped: \(Int(anagramsProps.skippedWords)) words")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.black)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(2)
                        .allowsTightening(true)
                    Text(" ☆ Longest word solved: \(anagramsProps.longestWord) letters")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.black)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(2)
                        .allowsTightening(true)
                }
            
            }
            Spacer()
            Text("\(score.finalScore)")
                .font(.custom("LuloOne-Bold", size: 22))
                .foregroundColor(.black)
                .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                .lineLimit(1)
                .allowsTightening(true)
            Spacer()
                .frame(width: 20)
        }
        .padding(.vertical, 5)
        
        Divider()
            .background(.black)
            .padding(.horizontal, 30)
    }

    private var timeFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .none
        df.timeStyle = .short
        return df
    }

    private var dateOnlyFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }
}

// MARK: - MultiGameLeaderboardView
struct MultiGameLeaderboardView: View {
    
    @Environment(\.sizeCategory) var sizeCategory
    @EnvironmentObject var scoreManager: GameScoreManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentTabIndex: Int = 0
    @State private var navigateToGame: String? = nil
    
    private let games: [GameInfo]
    
    init(selectedGameID: String? = nil) {
        self.games = GameInfo.availableGames
        if let gameID = selectedGameID,
           let index = games.firstIndex(where: { $0.id.lowercased() == gameID.lowercased() }) {
            _currentTabIndex = State(initialValue: index)
        }
    }
    
    var body: some View {
        NavigationStack {
        ZStack{
                Color.black.ignoresSafeArea()
                LinearGradient.highscoresNavGradient.ignoresSafeArea()
                
                VStack {
                    // NEW: Header with home button and icon tabs
                    VStack(alignment: .center, spacing: 12) {
                        // Top bar with home button
                        HStack {
                            
                            Text("High Scores")
                                .font(.custom("LuloOne-Bold", size: 26))
                                .foregroundColor(.white)
                                .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                .lineLimit(2)
                                .allowsTightening(true)
                                .multilineTextAlignment(.center)
                            
                            Spacer()
                                .frame(width:10)
                            
                            NavigationLink(destination: MainMenuView(initialPage: 0)) {
                                HStack(alignment: .lastTextBaseline, spacing: 6) {
                                    Image(systemName: "house.fill")
                                        .font(.system(size: 14))
                                    Text("Home")
                                        .font(.custom("LuloOne-Bold", size: sizeCategory > .large ? 12 : 14))
                                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                        .lineLimit(1)
                                        .allowsTightening(true)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.myAccentColor1.opacity(0.3))
                                .cornerRadius(8)
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white, lineWidth: 0.5)
                            )
                            
                            
                        }
                        .frame(minHeight: 50)
                        .padding(.horizontal, 20)
                        
                        // Game icon tabs
                        HStack(spacing: 30) {
                            ForEach(0..<games.count, id: \.self) { index in
                                VStack(spacing: 10) {
                                    // Game icon
                                    games[index].gameIcon
                                        .font(.system(size: 26))
                                        .foregroundColor(currentTabIndex != index ? Color.myAccentColor1 : .white.opacity(0.8))
                                        .shadow(color: (currentTabIndex != index ? Color.myNavy : Color.clear), radius:1)
                                    
                                    // Game name
                                    Text(games[index].displayName)
                                        .font(.custom("LuloOne-Bold", size: sizeCategory > .large ? 10 : 12))
                                        .foregroundColor(currentTabIndex != index ? Color.myAccentColor1 : Color.white.opacity(0.8))
                                        .shadow(color: (currentTabIndex != index ? Color.myNavy : Color.clear), radius:1)
                                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                        .lineLimit(1)
                                        .allowsTightening(true)
                                    
                                    // Active indicator dot
                                    Circle()
                                        .fill(currentTabIndex == index ? Color.white : Color.clear)
                                        .frame(width: 6, height: 6)
                                    
                                }
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentTabIndex = index
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        
                    }
                    .padding(.top, 15)
                    
                    
                    // TabView content
                    TabView(selection: $currentTabIndex) {
                        ForEach(0..<games.count, id: \.self) { index in
                            LeaderboardPageView(
                                gameID: games[index].id.lowercased(),
                                title: "\(games[index].displayName) Leaderboard",
                                onPlayGame: { navigateToGame = games[index].id }
                            )
                            .tag(index)
                            .padding(.top, 20)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .frame(height: 0.5)
                            .foregroundColor(Color.black),
                        alignment: .top
                    )
                }
                .navigationDestination(isPresented: Binding<Bool>(
                    get: { navigateToGame != nil },
                    set: { if !$0 { navigateToGame = nil } }
                )) {
                    if let gameId = navigateToGame {
                        gameDestinationView(for: gameId)
                    }
                }
            }
            .navigationBarBackButtonHidden(true) // Hide the default back button
            .onAppear {
                // MIXPANEL ANALYTICS CAPTURE
                Mixpanel.mainInstance().track(event: "High Scores Page View", properties: [
                    "app": "Decode! Daily iOS",
                    "build_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"],
                    "date": Date().formatted(),
                    "subscription_tier": SubscriptionManager.shared.currentTier.displayName
                ])
                print("📈 🪵 MIXPANEL DATA LOG EVENT: High Scores Page View")
                print("📈 🪵 date: \(Date().formatted())")
                print("📈 🪵 sub tier: \(SubscriptionManager.shared.currentTier.displayName)")
            }
        }
        
    }
    
    private func gameDestinationView(for gameId: String) -> AnyView {
        switch gameId {
        case "decode":
            return AnyView(DecodeGameView().environmentObject(scoreManager))
        case "flashdance":
            return AnyView(FlashdanceGameView().environmentObject(scoreManager))
        case "anagrams":
            return AnyView(AnagramsGameView().environmentObject(scoreManager))
        default:
            return AnyView(EmptyView())
        }
    }
}


