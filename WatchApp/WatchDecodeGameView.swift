import SwiftUI

struct WatchDecodeGameView: View {
    @StateObject private var game = DecodeGame(scoreManager: GameScoreManager.shared)
    @EnvironmentObject var gameScoreManager: GameScoreManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedColor: Color?
    @State private var currentColumn = 0
    @State private var showingResult = false

    private let colors: [Color] = [
        Color(red: 0.8, green: 0.2, blue: 0.2),  // Red
        Color(red: 0.2, green: 0.6, blue: 0.9),  // Blue
        Color(red: 0.3, green: 0.8, blue: 0.3),  // Green
        Color(red: 0.9, green: 0.7, blue: 0.2),  // Yellow
        Color(red: 0.7, green: 0.3, blue: 0.8),  // Purple
        Color(red: 0.9, green: 0.5, blue: 0.2)   // Orange
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header
                VStack(spacing: 4) {
                    Text("Decode")
                        .font(.headline)
                    Text("Attempt \(game.currentRow + 1)/7")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)

                // Game board - show last 3 attempts
                VStack(spacing: 6) {
                    let startRow = max(0, game.currentRow - 2)
                    let endRow = min(6, game.currentRow + 1)

                    ForEach(startRow...endRow, id: \.self) { row in
                        HStack(spacing: 4) {
                            ForEach(0..<5) { col in
                                Circle()
                                    .fill(game.board[row][col])
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            }

                            if row < game.currentRow {
                                FeedbackView(exact: game.exactMatches[row], partial: game.partialMatches[row])
                            }
                        }
                    }
                }
                .padding(.vertical, 8)

                if !game.gameOver {
                    // Current row builder
                    VStack(spacing: 8) {
                        Text("Building:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            ForEach(0..<5) { col in
                                Circle()
                                    .fill(game.board[game.currentRow][col])
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .stroke(currentColumn == col ? Color.white : Color.white.opacity(0.3), lineWidth: currentColumn == col ? 2 : 1)
                                    )
                            }
                        }

                        // Color picker
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 35))], spacing: 8) {
                            ForEach(0..<colors.count, id: \.self) { index in
                                Circle()
                                    .fill(colors[index])
                                    .frame(width: 35, height: 35)
                                    .onTapGesture {
                                        selectColor(colors[index])
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
                } else {
                    // Game Over
                    VStack(spacing: 8) {
                        Text(game.won ? "You Won!" : "Game Over")
                            .font(.title3)
                            .fontWeight(.bold)

                        Text("Score: \(game.score)")
                            .font(.title2)

                        Button("Done") {
                            saveScore()
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Decode")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            game.loadDailyCode()
        }
    }

    private var canSubmit: Bool {
        game.board[game.currentRow].allSatisfy { $0 != .gray }
    }

    private func selectColor(_ color: Color) {
        if currentColumn < 5 {
            game.board[game.currentRow][currentColumn] = color
            currentColumn += 1
        }
    }

    private func submitGuess() {
        game.submitGuess()
        currentColumn = 0
    }

    private func saveScore() {
        // Score is automatically saved by the game when it ends
        // No need to manually save here
    }
}

struct FeedbackView: View {
    let exact: Int
    let partial: Int

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                ForEach(0..<exact, id: \.self) { _ in
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                }
                ForEach(0..<partial, id: \.self) { _ in
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .frame(width: 30)
    }
}

#Preview {
    NavigationStack {
        WatchDecodeGameView()
            .environmentObject(GameScoreManager.shared)
    }
}
