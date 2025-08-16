//
//  DecodeGame.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/14/25.
//

import SwiftUI

class DecodeGame: GameProtocol {
    @Published var currentTurn: Int = 0
    @Published var gameOver: Int = 0
    @Published var statusText: String = ""
    @Published var theCode: [Int] = []
    @Published var theBoard: [[Int]] = []
    @Published var theScore: [[Int]] = []
    
    // Score tracking
    @Published var gameStartTime: Date?
    @Published var lastScore: GameScore?
    private let scoreManager = ScoreManager()
    
    // Game-specific colors
    let myPegColor1 = Color(red:49/255,green:52/255,blue:66/255)
    let myPegColor2 = Color(red:137/255,green:99/255,blue:145/255)
    let myPegColor3 = Color(red:143/255,green:159/255,blue:219/255)
    let myPegColor4 = Color(red:99/255,green:133/255,blue:145/255)
    let myPegColor5 = Color(red:200/255,green:105/255,blue:105/255)
    let myPegColor6 = Color(red:201/255,green:168/255,blue:97/255)
    
    @Published var pegShades: [Color] = [.gray, .white, .red, .orange, .yellow, .green]
    @Published var scoreShades: [Color] = [.clear, .yellow, .green]

    // Game configuration
    let numRows = 8
    let numCols = 4

    init() {
        startGame()
    }

    func startGame() {
        pegShades = [myPegColor1, myPegColor2, myPegColor3, myPegColor4, myPegColor5, myPegColor6]
        currentTurn = 0
        gameOver = 0
        theCode = (0..<numCols).map { _ in Int.random(in: 1..<pegShades.count) }
        theBoard = Array(repeating: Array(repeating: 0, count: numCols), count: numRows)
        theScore = Array(repeating: Array(repeating: 0, count: numCols), count: numRows)
        statusText = "Try to guess the hidden color code ➜ tap each square to assign a color."
        
        // Start timing
        gameStartTime = Date()
        lastScore = nil
    }
    
    func resetGame() {
        startGame() // For Decode, reset is the same as start
    }

    func checkRow(_ row: Int) -> Bool {
        var check = true
        
        for col in (0..<numCols) {
            if theBoard[row][col] == 0 {
                check = false
                statusText = "Assign every square a color."
            }
        }
        return check
    }

    func scoreRow(_ row: Int) {
        guard row == currentTurn else { return }
        
        if checkRow(row) {
            var exactMatches = 0
            var colorCounts = [Int: Int]()
            
            for peg in theCode {
                colorCounts[peg, default: 0] += 1
            }
            
            for col in 0..<numCols {
                if theBoard[row][col] == theCode[col] {
                    exactMatches += 1
                    colorCounts[theBoard[row][col]]! -= 1
                }
            }
            
            var partialMatches = 0
            for col in 0..<numCols where theBoard[row][col] != theCode[col] {
                if let count = colorCounts[theBoard[row][col]], count > 0 {
                    partialMatches += 1
                    colorCounts[theBoard[row][col]]! -= 1
                }
            }
            
            for col in 0..<exactMatches {
                theScore[row][col] = 2
            }
            for col in exactMatches..<(exactMatches + partialMatches) {
                theScore[row][col] = 1
            }
            
            statusText = "You got \(exactMatches) color\(exactMatches == 1 ? " " : "s ")in the RIGHT spot.\n You got \(partialMatches) color\(partialMatches == 1 ? " " : "s ")in the WRONG spot. \n\nTry again."
            currentTurn += 1
            
            if currentTurn > numRows-1 {
                gameOver = 1
                statusText = "Sorry, you're out of guesses. maybe next time!"
                saveGameScore(won: false)
            }
            
            if exactMatches == 4 {
                gameOver = 1
                statusText = "You cracked the code! Nice job!"
                saveGameScore(won: true)
                
                if let score = lastScore {
                    statusText += "\n\nScore: \(score.finalScore) points"
                    statusText += "\nTime: \(score.formattedTime)"
                    statusText += "\nAttempts: \(score.attempts)"
                    statusText += "\n\nTap to play again."
                }
            }
        }
    }
    
    // MARK: - Score Management
    
    private func saveGameScore(won: Bool) {
        guard let startTime = gameStartTime else { return }
        
        let timeElapsed = Date().timeIntervalSince(startTime)
        let attempts = currentTurn // currentTurn represents attempts made
        let finalScore = ScoreManager.calculateDecodeScore(
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
        
        scoreManager.saveScore(gameScore)
        lastScore = gameScore
    }
    
    // Get recent scores for this game type
    func getRecentScores() -> [GameScore] {
        return scoreManager.getScores(for: "decode")
    }
}
