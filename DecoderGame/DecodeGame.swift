import SwiftUI

class DecodeGame: ObservableObject, GameProtocol {
    @Published var currentTurn: Int = 0
    @Published var gameOver: Int = 0
    @Published var statusText: String = ""
    @Published var theCode: [Int] = []
    @Published var theBoard: [[Int]] = []
    @Published var theScore: [[Int]] = []

    @Published var gameStartTime: Date?
    @Published var lastScore: GameScore?

    // Make scoreManager mutable so it can be injected after initialization
    var scoreManager: GameScoreManager

    // Colors
    let myPegColor1 = Color(red:49/255,green:52/255,blue:66/255)
    let myPegColor2 = Color(red:137/255,green:99/255,blue:145/255)
    let myPegColor3 = Color(red:143/255,green:159/255,blue:219/255)
    let myPegColor4 = Color(red:99/255,green:133/255,blue:145/255)
    let myPegColor5 = Color(red:200/255,green:105/255,blue:105/255)
    let myPegColor6 = Color(red:201/255,green:168/255,blue:97/255)

    @Published var pegShades: [Color] = []
    @Published var scoreShades: [Color] = [.clear, .yellow, .green]

    let numRows = 8
    let numCols = 4

    init(scoreManager: GameScoreManager) {
        self.scoreManager = scoreManager
        startGame()
    }
    
    let gameInfo = GameInfo(
           id: "decode",
           displayName: "decode",
           description: "crack the color code",
           isAvailable: true,
           gameLocation: DecodeGameView()
       )


    func startGame() {
        pegShades = [myPegColor1, myPegColor2, myPegColor3, myPegColor4, myPegColor5, myPegColor6]
        currentTurn = 0
        gameOver = 0
        theCode = (0..<numCols).map { _ in Int.random(in: 1..<pegShades.count) }
        theBoard = Array(repeating: Array(repeating: 0, count: numCols), count: numRows)
        theScore = Array(repeating: Array(repeating: 0, count: numCols), count: numRows)
        statusText = "Try to guess the hidden color code ➜ tap each square to assign a color."
        gameStartTime = Date()
        lastScore = nil
        
        // Debug logging to verify scoreManager is connected
        print("DecodeGame initialized with scoreManager: \(type(of: scoreManager))")
    }

    func resetGame() {
        startGame()
    }

    func checkRow(_ row: Int) -> Bool {
        for col in 0..<numCols {
            if theBoard[row][col] == 0 {
                statusText = "Assign every square a color."
                return false
            }
        }
        return true
    }

    func scoreRow(_ row: Int) {
        guard row == currentTurn else { return }

        if checkRow(row) {
            var exactMatches = 0
            var colorCounts = [Int: Int]()

            // Count colors in the code
            for peg in theCode { colorCounts[peg, default: 0] += 1 }

            // Check for exact matches first
            for col in 0..<numCols {
                if theBoard[row][col] == theCode[col] {
                    exactMatches += 1
                    colorCounts[theBoard[row][col]]! -= 1
                }
            }

            // Check for partial matches (right color, wrong position)
            var partialMatches = 0
            for col in 0..<numCols where theBoard[row][col] != theCode[col] {
                if let count = colorCounts[theBoard[row][col]], count > 0 {
                    partialMatches += 1
                    colorCounts[theBoard[row][col]]! -= 1
                }
            }

            // Set score indicators
            for col in 0..<exactMatches { theScore[row][col] = 2 } // Green dots
            for col in exactMatches..<(exactMatches + partialMatches) { theScore[row][col] = 1 } // Yellow dots

            // Update status text
            statusText = "You got \(exactMatches) color\(exactMatches == 1 ? " " : "s ")in the RIGHT spot.\nYou got \(partialMatches) color\(partialMatches == 1 ? " " : "s ")in the WRONG spot.\n\nTry again."
            currentTurn += 1

            // Check win condition
            if exactMatches == numCols {
                gameOver = 1
                statusText = "You cracked the code! Nice job!"
                saveGameScore(won: true)

                if let score = lastScore {
                    statusText += "\n\nScore: \(score.finalScore) points"
                    statusText += "\nTime: \(score.formattedTime)"
                    statusText += "\nAttempts: \(score.attempts)"
                    statusText += "\n\nTap to play again."
                }
                return
            }

            // Check lose condition (out of attempts)
            if currentTurn >= numRows {
                gameOver = 1
                statusText = "Sorry, you're out of guesses. Maybe next time!"
                saveGameScore(won: false)
            }
        }
    }

    private func saveGameScore(won: Bool) {
        guard let startTime = gameStartTime else {
            print("Error: No start time recorded for game")
            return
        }

        let timeElapsed = Date().timeIntervalSince(startTime)
        let attempts = currentTurn
        let finalScore = GameScoreManager.calculateDecodeScore(
            attempts: attempts,
            timeElapsed: timeElapsed,
            won: won,
            maxAttempts: numRows
        )

        let gameScore = GameScore(
            gameId: "decode",
            date: Date(),
            attempts: attempts,
            timeElapsed: timeElapsed,
            won: won,
            finalScore: finalScore
        )

        print("Saving game score: \(finalScore) points, won: \(won), attempts: \(attempts)")
        
        // Save the score using the injected score manager
        scoreManager.saveScore(gameScore)
        lastScore = gameScore
        
        print("Score saved successfully to \(type(of: scoreManager))")
    }

    func getRecentScores() -> [GameScore] {
        return scoreManager.getScores(for: "decode")
    }
}
