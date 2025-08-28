//
// MultiGameLeaderboardView.swift
//

import SwiftUI

// MARK: - Single Leaderboard Page
struct LeaderboardPageView: View {
    let gameID: String
    let title: String
    let gameDestination: AnyView

    @EnvironmentObject var scoreManager: GameScoreManager

    var body: some View {
        VStack {
            if filteredScores.isEmpty {
                NoScoresView(gameDestination: gameDestination)
            } else {
                VStack {
                    LeaderboardHeaderText(count: filteredScores.count)
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(filteredScores) { score in
                                ScoreRowView(score: score)
                            }
                        }
                    }
                }
            }
        }
        .animation(.default, value: scoreManager.allScores)
    }

    private var filteredScores: [GameScore] {
        scoreManager.allScores
            .filter { $0.gameId == gameID }
            .sorted {
                if $0.finalScore == $1.finalScore {
                    // if tied, keep most recent first
                    return $0.date > $1.date
                }
                return $0.finalScore > $1.finalScore
            }
    }
}

// MARK: - Subviews
struct NoScoresView: View {
    let gameDestination: AnyView

    var body: some View {
        Spacer().frame(height: 20)
        VStack(spacing: 10) {
            Text("No scores yet!")
                .font(.custom("LuloOne-Bold", size: 12))
                .foregroundColor(.secondary)

            Spacer()
                .frame(height:10)
            
            NavigationLink(destination: gameDestination) {
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
        .foregroundColor(.secondary)
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
                    
                    Text(" ⋰⋰⋰ ")
                        .font(.custom("LuloOne-Bold", size: 10))
                        .foregroundColor(.secondary)
                    
                    Text(timeFormatter.string(from: score.date))
                        .font(.custom("LuloOne-Bold", size: 12))
                }
                
                // CUSTOM SCORE EXTRAS
                
                if let flashdanceProps = score.flashdanceProperties {
                    Text("Equations solved: \(flashdanceProps.correctAnswers)")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.secondary)
                    Text("Longest Streak: \(flashdanceProps.longestStreak) in a row")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.secondary)
                    Text("Incorrect Answers: \(flashdanceProps.incorrectAnswers)")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.secondary)
                }
                
                if let decodeProps = score.decodeProperties {
                    Text("Guesses: \(decodeProps.turnsToSolve)")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.secondary)
                    Text("Code Size: \(decodeProps.codeLength)")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.secondary)
                }
                
                if let anagramsProps = score.anagramsProperties {
                    Text("Solved: \(Int(anagramsProps.wordsCompleted)) words")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.black)
                    Text("  (\(anagramsProps.totalWordsInSet) words possible)")
                        .font(.custom("LuloOne", size: 12))
                        .foregroundColor(.secondary)
                    Text("Longest word solved: \(anagramsProps.longestWord) letters")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.black)
                    Text("Timer: \(Int(score.timeElapsed)) seconds")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.black)
                    
                }
            
                Divider()
            }
            Spacer()
            Text("\(score.finalScore)")
                .font(.custom("LuloOne-Bold", size: 22))
            Spacer()
                .frame(width: 20)
        }
        .padding(.vertical, 5)
        //.padding(.horizontal, 10)
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

    private let games: [GameInfo]

    init(selectedGameID: String? = nil) {
        self.games = GameInfo.availableGames
        if let gameID = selectedGameID,
           let index = games.firstIndex(where: { $0.id.lowercased() == gameID.lowercased() }) {
            _currentTabIndex = State(initialValue: index)
        }
    }

    var body: some View {
        VStack {
            // Top arrows
            HStack {
                Button(action: {
                    withAnimation {
                        currentTabIndex = (currentTabIndex - 1 + games.count) % games.count
                    }
                }) {
                    Image(systemName: "arrowshape.backward.circle.fill")
                        .foregroundColor(.black) // always enabled now
                        .font(.system(size: 22))
                }

                Spacer()

                Text("\(games[currentTabIndex].displayName) Leaderboard")
                    .font(.custom("LuloOne-Bold", size: 22))

                Spacer()

                Button(action: {
                    withAnimation {
                        currentTabIndex = (currentTabIndex + 1) % games.count
                    }
                }) {
                    Image(systemName: "arrowshape.forward.circle.fill")
                        .foregroundColor(.black) // always enabled now
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
                        gameDestination: games[index].gameLocation
                    )
                    .tag(index)
                    .padding(.top, 20)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}

extension DateFormatter {
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)  // Match the wordset manager
        return formatter
    }()
}
