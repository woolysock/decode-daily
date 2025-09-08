//
// MultiGameLeaderboardView.swift
//

import SwiftUI

// MARK: - Single Leaderboard Page
struct LeaderboardPageView: View {
    let gameID: String
    let title: String
    let onPlayGame: () -> Void

    @EnvironmentObject var scoreManager: GameScoreManager

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
//                                Divider()
//                                    .background(.black)
//                                    .padding(.horizontal, 30)
                                
                                Spacer().frame(height:5)
                                
                                Button(action: onPlayGame) {
                                    VStack(spacing: 5) {
                                        Text("play")
                                            .font(.custom("LuloOne-Bold", size: 16))
                                        Text(gameDisplayName.lowercased())
                                            .font(.custom("LuloOne-Bold", size: 16))
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
    
    // Add computed property to get game display name
    // Add computed property to get game display name
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
    let onPlayGame: () -> Void
    
    var body: some View {
        Spacer().frame(height: 20)
        VStack(spacing: 10) {
            Text("No scores yet!")
                .font(.custom("LuloOne-Bold", size: 12))
                .foregroundColor(.black)  // Changed from .secondary
            
            Spacer().frame(height:10)
            
            Button(action: onPlayGame) {
                VStack(spacing: 5) {
                    Text("play")
                        .font(.custom("LuloOne-Bold", size: 16))
                    Text("now")
                        .font(.custom("LuloOne-Bold", size: 16))
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

    var body: some View {
        Text(
            count == 0
                ? "You have no high scores"
                : "You have \(count) high score\(count == 1 ? "" : "s")"
        )
        .font(.custom("LuloOne", size: 12))
        .foregroundColor(.black)  // Changed from .secondary
        .padding(.bottom, 5)
    }
}

struct ScoreRowView: View {
    let score: GameScore

    var body: some View {
        HStack(spacing: 5) {
            Spacer()
                .frame(width: 20)
            VStack(alignment: .leading) {
                
                HStack(spacing: 4) {
                    Text(dateOnlyFormatter.string(from: score.date))
                        .font(.custom("LuloOne-Bold", size: 12))
                        .foregroundColor(.black)
                    
                    Text(" ⋰ ")
                        .font(.custom("LuloOne-Bold", size: 10))
                        .foregroundColor(Color.myAccentColor1)
                    
                    Text(timeFormatter.string(from: score.date))
                        .font(.custom("LuloOne-Bold", size: 12))
                        .foregroundColor(.black)
                }
                
                // CUSTOM SCORE EXTRAS
                
                if let flashdanceProps = score.flashdanceProperties {
                    if let the_date = score.archiveDate {
                        Text("Game ID: \(DateFormatter.dayFormatter.string(from: the_date))\n")
                            .font(.custom("LuloOne", size: 10))
                            .foregroundColor(.black)
                    } else {
                        Text("Game ID: Not Found\n")
                            .font(.custom("LuloOne", size: 10))
                            .foregroundColor(.black)
                    }
                    
                    Text(" ☆ Equations solved: \(flashdanceProps.correctAnswers)")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.black)
                        
                    Text(" ☆ Wrong Answers: \(flashdanceProps.incorrectAnswers)")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.black)
                    
                    Text(" ☆ Longest Streak: \(flashdanceProps.longestStreak) in a row")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.black)
                }
                
                if let decodeProps = score.decodeProperties {
                    if let the_date = score.archiveDate {
                        Text("Game ID: \(DateFormatter.dayFormatter.string(from: the_date))\n")
                            .font(.custom("LuloOne", size: 10))
                            .foregroundColor(.black)
                    } else {
                        Text("Game ID: Not Found\n")
                            .font(.custom("LuloOne", size: 10))
                            .foregroundColor(.black)
                    }
                    Text(" ☆ Guesses: \(decodeProps.turnsToSolve)")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.black)
                    
                    let duration = Int(decodeProps.gameDuration)
                    let timeText = duration < 60 ? "\(duration) sec" : String(format: "%d:%02d", duration / 60, duration % 60)
                    
                    Text(" ☆ Time to Solve: \(timeText)")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.black)
                }
                
                if let anagramsProps = score.anagramsProperties {
                    if let the_date = score.archiveDate {
                        Text("Game ID: \(DateFormatter.dayFormatter.string(from: the_date))\n")
                            .font(.custom("LuloOne", size: 10))
                            .foregroundColor(.black)
                    } else {
                        Text("Game ID: Not Found\n")
                            .font(.custom("LuloOne", size: 10))
                            .foregroundColor(.black)
                    }
                    Text(" ☆ Solved: \(Int(anagramsProps.wordsCompleted)) words (of \(anagramsProps.totalWordsInSet))")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.black)
                    Text(" ☆ Skipped: \(Int(anagramsProps.skippedWords)) words")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.black)
                    Text(" ☆ Longest word solved: \(anagramsProps.longestWord) letters")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.black)
                }
            
            }
            Spacer()
            Text("\(score.finalScore)")
                .font(.custom("LuloOne-Bold", size: 22))
                .foregroundColor(.black)  // Added explicit color
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
    @EnvironmentObject var scoreManager: GameScoreManager
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
        ZStack{
            VStack {
                // Top arrows
                HStack {
                    Button(action: {
                        withAnimation {
                            currentTabIndex = (currentTabIndex - 1 + games.count) % games.count
                        }
                    }) {
                        Image(systemName: "arrowshape.backward.circle.fill")
                            .foregroundColor(.black)
                            .font(.system(size: 22))
                    }
                    
                    Spacer()
                    
                    Text("\(games[currentTabIndex].displayName) Leaderboard")
                        .font(.custom("LuloOne-Bold", size: 22))
                        .foregroundColor(.black)  // Added explicit color
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            currentTabIndex = (currentTabIndex + 1) % games.count
                        }
                    }) {
                        Image(systemName: "arrowshape.forward.circle.fill")
                            .foregroundColor(.black)
                            .font(.system(size: 22))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Page TabView
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
        .background(Color.white)
    }
    
    // Add this helper method to create game destinations
    
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


