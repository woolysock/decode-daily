import SwiftUI

struct WatchFlashdanceGameView: View {
    @StateObject private var game = FlashdanceGame(scoreManager: GameScoreManager.shared)
    @EnvironmentObject var gameScoreManager: GameScoreManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            if !game.gameStarted {
                // Start screen
                VStack(spacing: 16) {
                    Text("Flashdance")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Solve as many equations as you can in 30 seconds!")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)

                    Button("Start Game") {
                        game.startGame()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if game.isPreCountdownActive {
                // Countdown: 3...2...1...
                VStack(spacing: 20) {
                    Text("Get Ready!")
                        .font(.headline)

                    Text("\(game.countdownValue)")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(.blue)
                }
                .padding()
            } else if game.isGameActive {
                // Game in progress
                VStack(spacing: 12) {
                    // Timer and Score
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.caption)
                            Text("\(game.gameTimeRemaining)s")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(game.gameTimeRemaining <= 5 ? .red : .primary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Score: \(game.score)")
                                .font(.headline)
                            Text("\(game.correctCount) correct")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal)

                    Divider()

                    // Current equation
                    if !game.currentEquation.isEmpty {
                        VStack(spacing: 16) {
                            Text(game.currentEquation)
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)

                            // Answer options
                            VStack(spacing: 8) {
                                ForEach(game.answers, id: \.self) { answer in
                                    Button(action: {
                                        submitAnswer(answer)
                                    }) {
                                        Text("\(answer)")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    } else {
                        // Loading next equation
                        ProgressView()
                            .padding()
                    }
                }
                .padding()
            } else if game.isGameOver {
                // Game Over
                VStack(spacing: 16) {
                    Text("Time's Up!")
                        .font(.title2)
                        .fontWeight(.bold)

                    VStack(spacing: 8) {
                        Text("Final Score")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(game.score)")
                            .font(.system(size: 48, weight: .bold))

                        Divider()
                            .padding(.vertical, 4)

                        HStack(spacing: 20) {
                            VStack {
                                Text("\(game.correctCount)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                Text("Correct")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            VStack {
                                Text("\(game.incorrectCount)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                Text("Wrong")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)

                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .navigationTitle("Flashdance")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func submitAnswer(_ answer: Int) {
        _ = game.checkAnswer(selected: answer)
        // Game automatically handles scoring and moving to next equation
    }
}

#Preview {
    NavigationStack {
        WatchFlashdanceGameView()
            .environmentObject(GameScoreManager.shared)
    }
}
