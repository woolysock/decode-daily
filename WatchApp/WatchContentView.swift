import SwiftUI

struct WatchContentView: View {
    @EnvironmentObject var gameCoordinator: GameCoordinator
    @State private var selectedGame: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: WatchDecodeGameView()) {
                        GameRowView(
                            title: "Decode",
                            icon: "lock.circle.fill",
                            color: Color(red: 0.2, green: 0.4, blue: 0.8)
                        )
                    }

                    NavigationLink(destination: WatchFlashdanceGameView()) {
                        GameRowView(
                            title: "Flashdance",
                            icon: "bolt.circle.fill",
                            color: Color(red: 0.8, green: 0.2, blue: 0.4)
                        )
                    }

                    NavigationLink(destination: WatchAnagramsGameView()) {
                        GameRowView(
                            title: "Anagrams",
                            icon: "character.textbox",
                            color: Color(red: 0.4, green: 0.7, blue: 0.3)
                        )
                    }
                }

                Section("Scores") {
                    NavigationLink(destination: WatchScoresView()) {
                        Label("View Scores", systemImage: "list.number")
                    }
                }
            }
            .navigationTitle("Decode! Daily")
        }
    }
}

struct GameRowView: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)

            Text(title)
                .font(.headline)
        }
        .padding(.vertical, 4)
    }
}

struct WatchScoresView: View {
    @EnvironmentObject var gameScoreManager: GameScoreManager

    private var todaysDecodeScore: Int? {
        let today = Calendar.current.startOfDay(for: Date())
        return gameScoreManager.allScores
            .filter { $0.gameId == "decode" && Calendar.current.isDate($0.date, inSameDayAs: today) }
            .first?.finalScore
    }

    private var todaysFlashdanceScore: Int? {
        let today = Calendar.current.startOfDay(for: Date())
        return gameScoreManager.allScores
            .filter { $0.gameId == "flashdance" && Calendar.current.isDate($0.date, inSameDayAs: today) }
            .first?.finalScore
    }

    private var todaysAnagramsScore: Int? {
        let today = Calendar.current.startOfDay(for: Date())
        return gameScoreManager.allScores
            .filter { $0.gameId == "anagrams" && Calendar.current.isDate($0.date, inSameDayAs: today) }
            .first?.finalScore
    }

    var body: some View {
        List {
            Section("Today's Scores") {
                ScoreRowView(game: "Decode", score: todaysDecodeScore)
                ScoreRowView(game: "Flashdance", score: todaysFlashdanceScore)
                ScoreRowView(game: "Anagrams", score: todaysAnagramsScore)
            }

            Section("Recent Games") {
                ForEach(gameScoreManager.getRecentScores(limit: 5)) { score in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(score.gameId.capitalized)
                                .font(.headline)
                            Spacer()
                            Text("\(score.finalScore)")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        Text(score.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Scores")
    }
}

struct ScoreRowView: View {
    let game: String
    let score: Int?

    var body: some View {
        HStack {
            Text(game)
            Spacer()
            if let score = score {
                Text("\(score)")
                    .foregroundColor(.secondary)
            } else {
                Text("Not played")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
    }
}

#Preview {
    WatchContentView()
        .environmentObject(GameCoordinator())
        .environmentObject(GameScoreManager.shared)
}
