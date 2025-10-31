import SwiftUI

struct WatchDecodeGameView: View {
    @StateObject private var game = DecodeGame(scoreManager: GameScoreManager.shared)
    @EnvironmentObject var gameScoreManager: GameScoreManager
    @Environment(\.dismiss) private var dismiss
    @State private var currentColumn = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header
                VStack(spacing: 4) {
                    Text("Decode")
                        .font(.headline)
                    if !game.isGameOver {
                        Text("Attempt \(game.currentRow + 1)/\(game.numRows)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 8)

                if game.code.isEmpty {
                    // Loading
                    ProgressView("Loading...")
                        .padding()
                } else if !game.isGameOver {
                    // Game in progress
                    VStack(spacing: 12) {
                        // Game board - show last 3 attempts
                        VStack(spacing: 6) {
                            let startRow = max(0, game.currentRow - 2)
                            let endRow = min(game.numRows - 1, game.currentRow)

                            ForEach(startRow...endRow, id: \.self) { row in
                                HStack(spacing: 4) {
                                    // Pegs
                                    ForEach(0..<game.numCols, id: \.self) { col in
                                        Circle()
                                            .fill(pegColor(forIndex: game.board[row][col]))
                                            .frame(width: 24, height: 24)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                            )
                                    }

                                    // Feedback for completed rows
                                    if row < game.currentRow {
                                        FeedbackView(scores: game.feedback[row])
                                            .frame(width: 30)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)

                        // Current row builder
                        VStack(spacing: 8) {
                            Text("Building:")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(spacing: 4) {
                                ForEach(0..<game.numCols, id: \.self) { col in
                                    Circle()
                                        .fill(pegColor(forIndex: game.board[game.currentRow][col]))
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Circle()
                                                .stroke(currentColumn == col ? Color.white : Color.white.opacity(0.3), lineWidth: currentColumn == col ? 2 : 1)
                                        )
                                }
                            }

                            // Color picker
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 35))], spacing: 8) {
                                ForEach(1...6, id: \.self) { colorIndex in
                                    Circle()
                                        .fill(pegColor(forIndex: colorIndex))
                                        .frame(width: 35, height: 35)
                                        .onTapGesture {
                                            selectColor(colorIndex)
                                        }
                                }
                            }
                            .padding(.horizontal)

                            // Submit button
                            Button(action: submitGuess) {
                                Text("Submit Guess")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(canSubmit ? Color.blue : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .disabled(!canSubmit)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                } else {
                    // Game Over
                    VStack(spacing: 12) {
                        Text(game.won ? "You Won!" : "Game Over")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(game.won ? .green : .red)

                        if game.won {
                            Text("Solved in \(game.currentRow) attempts!")
                                .font(.subheadline)
                        } else {
                            VStack(spacing: 4) {
                                Text("The code was:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                HStack(spacing: 4) {
                                    ForEach(0..<game.numCols, id: \.self) { col in
                                        Circle()
                                            .fill(pegColor(forIndex: game.code[col]))
                                            .frame(width: 24, height: 24)
                                    }
                                }
                            }
                        }

                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("Decode")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if game.code.isEmpty {
                game.startGame()
            }
        }
    }

    private var canSubmit: Bool {
        game.board[game.currentRow].allSatisfy { $0 != 0 }
    }

    private func selectColor(_ colorIndex: Int) {
        if currentColumn < game.numCols {
            game.theBoard[game.currentRow][currentColumn] = colorIndex
            currentColumn += 1
        }
    }

    private func submitGuess() {
        game.scoreRow(game.currentRow)
        currentColumn = 0
    }

    private func pegColor(forIndex index: Int) -> Color {
        switch index {
        case 0: return Color.gray.opacity(0.3)  // Empty
        case 1: return game.pegShades.count > 0 ? game.pegShades[0] : Color.gray
        case 2: return game.pegShades.count > 1 ? game.pegShades[1] : Color.gray
        case 3: return game.pegShades.count > 2 ? game.pegShades[2] : Color.gray
        case 4: return game.pegShades.count > 3 ? game.pegShades[3] : Color.gray
        case 5: return game.pegShades.count > 4 ? game.pegShades[4] : Color.gray
        case 6: return game.pegShades.count > 5 ? game.pegShades[5] : Color.gray
        default: return Color.gray
        }
    }
}

struct FeedbackView: View {
    let scores: [Int]

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                ForEach(0..<scores.count, id: \.self) { index in
                    if scores[index] == 2 {
                        // Exact match
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                    } else if scores[index] == 1 {
                        // Partial match
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        WatchDecodeGameView()
            .environmentObject(GameScoreManager.shared)
    }
}
