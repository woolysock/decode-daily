import SwiftUI

struct WatchAnagramsGameView: View {
    @StateObject private var game = AnagramsGame(scoreManager: GameScoreManager.shared)
    @EnvironmentObject var gameScoreManager: GameScoreManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if !game.gameStarted {
                    // Start screen
                    VStack(spacing: 16) {
                        Text("'Grams")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Unscramble as many words as you can in 60 seconds!")
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
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 4) {
                                    Image(systemName: "timer")
                                        .font(.caption)
                                    Text("\(game.gameTimeRemaining)s")
                                        .fontWeight(.bold)
                                        .foregroundColor(game.gameTimeRemaining <= 10 ? .red : .primary)
                                }
                                Text("Score: \(game.score)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text("\(game.wordsCompleted)/\(game.totalWords)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)

                        Divider()

                        // Scrambled letters
                        if !game.scrambledLetters.isEmpty {
                            VStack(spacing: 12) {
                                // Current answer being built
                                VStack(spacing: 4) {
                                    Text("Your word:")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)

                                    if game.userAnswer.isEmpty {
                                        Text("Tap letters below")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .italic()
                                    } else {
                                        Text(game.userAnswer.uppercased())
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .tracking(2)
                                    }
                                }
                                .frame(minHeight: 40)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)

                                // Letter selection grid
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 32))], spacing: 8) {
                                    ForEach(Array(game.scrambledLetters.enumerated()), id: \.offset) { index, letter in
                                        let isUsed = game.usedLetterIndices.contains(index)

                                        Text(letter.uppercased())
                                            .font(.headline)
                                            .frame(width: 32, height: 32)
                                            .background(isUsed ? Color.gray.opacity(0.5) : Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(6)
                                            .opacity(isUsed ? 0.5 : 1.0)
                                            .onTapGesture {
                                                game.selectLetter(at: index)
                                            }
                                    }
                                }
                                .padding(.horizontal)

                                // Action buttons
                                VStack(spacing: 8) {
                                    HStack(spacing: 8) {
                                        Button(action: clearSelection) {
                                            Text("Clear")
                                                .font(.subheadline)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 8)
                                                .background(game.userAnswer.isEmpty ? Color.gray.opacity(0.3) : Color.orange)
                                                .foregroundColor(.white)
                                                .cornerRadius(6)
                                        }
                                        .disabled(game.userAnswer.isEmpty)

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

                            VStack(spacing: 4) {
                                Text("Words solved: \(game.wordsCompleted)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                if !game.completedWordLengths.isEmpty {
                                    let longestWord = game.completedWordLengths.max() ?? 0
                                    Text("Longest word: \(longestWord) letters")
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
        }
        .navigationTitle("'Grams")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func clearSelection() {
        game.userAnswer = ""
        game.usedLetterIndices.removeAll()
    }

    private func skipWord() {
        game.skipCurrentWord()
    }
}

#Preview {
    NavigationStack {
        WatchAnagramsGameView()
            .environmentObject(GameScoreManager.shared)
    }
}
