//
//  MultiGameLeaderboardView.swift
//

import SwiftUI

struct MultiGameLeaderboardView: View {
    @EnvironmentObject var scoreManager: GameScoreManager

    @State private var currentTabIndex: Int = 0
    private let games = ["flashdance", "decode", "numbers"]

    var body: some View {
        VStack {
            // MARK: - Top title with arrows
            HStack {
                // Left arrow
                Button(action: {
                    if currentTabIndex > 0 {
                        withAnimation { currentTabIndex -= 1 }
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(currentTabIndex == 0 ? .white : .black)
                        .font(.title2)
                }
                .disabled(currentTabIndex == 0)

                Spacer()

                Text("\(games[currentTabIndex]) Leaderboard")
                    .font(.custom("LuloOne-Bold", size: 22))

                Spacer()

                // Right arrow
                Button(action: {
                    if currentTabIndex < games.count - 1 {
                        withAnimation { currentTabIndex += 1 }
                    }
                }) {
                    Image(systemName: "chevron.right")
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
            .tabViewStyle(.page(indexDisplayMode: .always)) // show default dots
        }
    }
}

// MARK: - Single Leaderboard Page
struct LeaderboardPageView: View {
    let gameID: String
    let title: String

    @EnvironmentObject var scoreManager: GameScoreManager

    var body: some View {
        VStack {
            // Use scoreManager.allScores directly in the body to ensure proper observation
            let filteredScores = scoreManager.allScores
                .filter { $0.gameId == gameID }
                .sorted { $0.date > $1.date }
            
            if filteredScores.isEmpty {
                Spacer()
                VStack {
                    Text("No scores yet!")
                        .font(.custom("LuloOne-Bold", size: 12))
                        .foregroundColor(.secondary)
                    
                    // Debug info
                    Text("Looking for: '\(gameID)'")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Total scores: \(scoreManager.allScores.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                VStack {
                    // Debug header
                    Text("there are \(filteredScores.count) saved scores!")
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
                                        .font(.custom("LuloOne-Bold", size: 12))
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
        .animation(.default, value: scoreManager.allScores) // Animate when allScores changes
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
