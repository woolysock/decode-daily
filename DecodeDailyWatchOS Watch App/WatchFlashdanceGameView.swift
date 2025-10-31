import SwiftUI

struct WatchFlashdanceGameView: View {
    @StateObject private var game = FlashdanceGame()
    @EnvironmentObject var gameScoreManager: GameScoreManager
    @Environment(\.dismiss) private var dismiss
    @State private var timeRemaining = 30
    @State private var timer: Timer?

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
                        startGame()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if !game.gameOver {
                // Game in progress
                VStack(spacing: 12) {
                    // Timer
                    HStack {
                        Image(systemName: "timer")
                        Text("\(timeRemaining)s")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(timeRemaining <= 5 ? .red : .primary)
                    }

                    // Score
                    Text("Score: \(game.score)")
                        .font(.headline)

                    Divider()

                    // Current equation
                    if let equation = game.currentEquation {
                        VStack(spacing: 16) {
                            Text(equation.equation)
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)

                            // Answer options
                            VStack(spacing: 8) {
                                ForEach(equation.options, id: \.self) { option in
                                    Button(action: {
                                        submitAnswer(option)
                                    }) {
                                        Text("\(option)")
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
                    }
                }
                .padding()
            } else {
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

                        Text("Correct: \(game.correctCount)")
                            .font(.subheadline)
                            .foregroundColor(.green)
                        Text("Incorrect: \(game.incorrectCount)")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    Button("Done") {
                        saveScore()
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

    private func startGame() {
        game.loadDailyEquations()
        game.startGame()
        startTimer()
    }

    private func startTimer() {
        timeRemaining = 30
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                endGame()
            }
        }
    }

    private func submitAnswer(_ answer: Int) {
        game.submitAnswer(answer)
    }

    private func endGame() {
        timer?.invalidate()
        timer = nil
        game.endGame()
    }

    private func saveScore() {
        gameScoreManager.recordFlashdanceScore(game.score, forDate: Date())
    }
}

#Preview {
    NavigationStack {
        WatchFlashdanceGameView()
            .environmentObject(GameScoreManager.shared)
    }
}
