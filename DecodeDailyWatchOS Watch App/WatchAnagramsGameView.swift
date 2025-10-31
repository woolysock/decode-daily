import SwiftUI

struct WatchAnagramsGameView: View {
    @StateObject private var game = AnagramsGame()
    @EnvironmentObject var gameScoreManager: GameScoreManager
    @Environment(\.dismiss) private var dismiss
    @State private var timeRemaining = 60
    @State private var timer: Timer?
    @State private var selectedLetters: [Character] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if !game.gameStarted {
                    // Start screen
                    VStack(spacing: 16) {
                        Text("Anagrams")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Unscramble as many words as you can in 60 seconds!")
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
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Image(systemName: "timer")
                                    Text("\(timeRemaining)s")
                                        .fontWeight(.bold)
                                        .foregroundColor(timeRemaining <= 10 ? .red : .primary)
                                }
                                Text("Score: \(game.score)")
                                    .font(.caption)
                            }

                            Spacer()

                            Text("Word \(game.currentWordIndex + 1)/\(game.totalWords)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)

                        Divider()

                        // Scrambled letters
                        if let scrambled = game.currentScrambledWord {
                            VStack(spacing: 12) {
                                Text("Unscramble:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text(scrambled.uppercased())
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .tracking(2)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)

                                // Current word being built
                                if !selectedLetters.isEmpty {
                                    VStack(spacing: 4) {
                                        Text("Your word:")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)

                                        Text(String(selectedLetters))
                                            .font(.headline)
                                            .tracking(1)
                                    }
                                }

                                // Letter selection
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 32))], spacing: 8) {
                                    ForEach(Array(scrambled.enumerated()), id: \.offset) { index, letter in
                                        Text(String(letter).uppercased())
                                            .font(.headline)
                                            .frame(width: 32, height: 32)
                                            .background(selectedLetters.contains(letter) ? Color.gray : Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(6)
                                            .onTapGesture {
                                                toggleLetter(letter)
                                            }
                                    }
                                }
                                .padding(.horizontal)

                                // Actions
                                VStack(spacing: 8) {
                                    Button(action: submitWord) {
                                        Text("Submit")
                                            .font(.headline)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(selectedLetters.count >= 3 ? Color.green : Color.gray)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                    .disabled(selectedLetters.count < 3)

                                    HStack(spacing: 8) {
                                        Button(action: clearSelection) {
                                            Text("Clear")
                                                .font(.subheadline)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 8)
                                                .background(Color.orange)
                                                .foregroundColor(.white)
                                                .cornerRadius(6)
                                        }

                                        Button(action: skipWord) {
                                            Text("Skip")
                                                .font(.subheadline)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 8)
                                                .background(Color.red)
                                                .foregroundColor(.white)
                                                .cornerRadius(6)
                                        }
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

                            Text("Words solved: \(game.wordsCompleted)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
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
        }
        .navigationTitle("Anagrams")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func startGame() {
        game.loadDailyWordset()
        game.startGame()
        startTimer()
    }

    private func startTimer() {
        timeRemaining = 60
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                endGame()
            }
        }
    }

    private func toggleLetter(_ letter: Character) {
        if let index = selectedLetters.firstIndex(of: letter) {
            selectedLetters.remove(at: index)
        } else {
            selectedLetters.append(letter)
        }
    }

    private func clearSelection() {
        selectedLetters.removeAll()
    }

    private func submitWord() {
        let word = String(selectedLetters).lowercased()
        game.submitWord(word)
        selectedLetters.removeAll()
    }

    private func skipWord() {
        game.skipWord()
        selectedLetters.removeAll()
    }

    private func endGame() {
        timer?.invalidate()
        timer = nil
        game.endGame()
    }

    private func saveScore() {
        gameScoreManager.recordAnagramsScore(game.score, forDate: Date())
    }
}

#Preview {
    NavigationStack {
        WatchAnagramsGameView()
            .environmentObject(GameScoreManager.shared)
    }
}
