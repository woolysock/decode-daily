//
// MultiGameLeaderboardView.swift
//

import SwiftUI

// MARK: - Single Leaderboard Page
struct LeaderboardPageView: View {
    let gameID: String
    let title: String

    @EnvironmentObject var scoreManager: GameScoreManager

    var body: some View {
        VStack {
            let filteredScores = scoreManager.allScores
                .filter { $0.gameId == gameID }
                .sorted { $0.date > $1.date }

            if filteredScores.isEmpty {
                Spacer().frame(height: 20)
                VStack(spacing: 10) {
                    Text("No scores yet!")
                        .font(.custom("LuloOne-Bold", size: 12))
                        .foregroundColor(.secondary)
                    
                    NavigationLink(destination: MainMenuView()) {
                        VStack(spacing: 5) {
                            Text("play")
                                .font(.custom("LuloOne-Bold", size: 16))
                            Text("")
                                .font(.custom("LuloOne", size: 10))
                        }
                        .padding()
                        .fixedSize()
                        .frame(height: 60)
                        .background(Color.myAccentColor2)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                Spacer()
            } else {
                VStack {
                    Text(
                        filteredScores.count == 0
                            ? "You have no high scores."
                            : "You have \(filteredScores.count) high score\(filteredScores.count == 1 ? "" : "s")."
                    )
                    .font(.custom("LuloOne", size: 12))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 5)
                    
                    List(filteredScores) { score in
                        HStack {
                            VStack(alignment: .leading) {
                                HStack(spacing: 4) {
                                    Text(timeFormatter.string(from: score.date))
                                        .font(.custom("LuloOne-Bold", size: 12))
                                    Text(" ⋰⋰⋰ ")
                                        .font(.custom("LuloOne-Bold", size: 10))
                                        .foregroundColor(.secondary)
                                    Text(dateOnlyFormatter.string(from: score.date))
                                        .font(.custom("LuloOne-Bold", size: 12))
                                }
                                Text("\(Int(score.timeElapsed))s game")
                                    .font(.custom("LuloOne", size: 12))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(score.finalScore)")
                                .font(.custom("LuloOne-Bold", size: 22))
                        }
                        .padding(.vertical, 5)
                    }
                    .listStyle(.plain)
                }
            }
        }
        .animation(.default, value: scoreManager.allScores)
        .onAppear {
            print("📱 LeaderboardPageView appeared for '\(gameID)' - showing \(scoreManager.allScores.filter { $0.gameId == gameID }.count) scores")
        }
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
    @State private var currentTabIndex: Int
    private let games = ["flashdance", "decode", "numbers", "anagrams"]

    // Custom initializer to select a specific game tab
    init(selectedGameID: String? = nil) {
        if let gameID = selectedGameID,
           let index = ["flashdance", "decode", "numbers", "anagrams"].firstIndex(of: gameID.lowercased()) {
            _currentTabIndex = State(initialValue: index)
        } else {
            _currentTabIndex = State(initialValue: 0)
        }
    }

    var body: some View {
        VStack {
            // MARK: - Top title with arrows
            HStack {
                Button(action: {
                    if currentTabIndex > 0 {
                        withAnimation { currentTabIndex -= 1 }
                    }
                }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(currentTabIndex == 0 ? .white : .black)
                        .font(.title2)
                }
                .disabled(currentTabIndex == 0)

                Spacer()

                Text("\(games[currentTabIndex]) Leaderboard")
                    .font(.custom("LuloOne-Bold", size: 22))

                Spacer()

                Button(action: {
                    if currentTabIndex < games.count - 1 {
                        withAnimation { currentTabIndex += 1 }
                    }
                }) {
                    Image(systemName: "arrow.right")
                        .foregroundColor(currentTabIndex == games.count - 1 ? .white : .black)
                        .font(.title2)
                }
                .disabled(currentTabIndex == games.count - 1)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            // MARK: - Page TabView
            TabView(selection: $currentTabIndex) {
                ForEach(0..<games.count, id: \.self) { index in
                    LeaderboardPageView(gameID: games[index].lowercased(), title: "\(games[index]) Leaderboard")
                        .tag(index)
                        .padding(.top, 20)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}
