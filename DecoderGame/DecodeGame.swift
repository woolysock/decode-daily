
//
//  DecodeGame.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/14/25.
//

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
    
    // Animation state
    @Published var isAnimating = false
    @Published var animatedCode: [Int] = []
    @Published var gameInteractive = false

    // Make scoreManager mutable so it can be injected after initialization
    var scoreManager: GameScoreManager
    
    // Animation timer
    private var animationTimer: Timer?
    private var animationStartTime: Date?

    // Colors
    let myPegColor1 = Color(red:49/255,green:52/255,blue:66/255)
    let myPegColor2 = Color(red:137/255,green:99/255,blue:145/255)
    let myPegColor3 = Color(red:143/255,green:159/255,blue:219/255)
    let myPegColor4 = Color(red:99/255,green:133/255,blue:145/255)
    let myPegColor5 = Color(red:200/255,green:105/255,blue:105/255)
    let myPegColor6 = Color(red:201/255,green:168/255,blue:97/255)

    @Published var pegShades: [Color] = []
    @Published var scoreShades: [Color] = [.clear, .yellow, .green]

    let numRows = 7
    let numCols = 5
    
    init(scoreManager: GameScoreManager) {
        self.scoreManager = scoreManager
        startGame()
        
        //this is nothing to do with the game, just lists post-script names of fonts in the console
//        for family in UIFont.familyNames {
//            print("Family: \(family)")
//            for name in UIFont.fontNames(forFamilyName: family) {
//                print("  Font: \(name)")
//            }
//        }
    }
    
    let gameInfo = GameInfo(
           id: "decode",
           displayName: "decode",
           description: "crack the color code",
           isAvailable: true,
           gameLocation: AnyView(DecodeGameView()),
           gameIcon: Image(systemName: "circle.hexagonpath")
       )


    func startGame() {
        // Set animation state FIRST to hide the board
        isAnimating = true
        gameInteractive = false
        
        pegShades = [myPegColor1, myPegColor2, myPegColor3, myPegColor4, myPegColor5, myPegColor6]
        currentTurn = 0
        gameOver = 0
        
        theCode = (0..<numCols).map { _ in Int.random(in: 1..<pegShades.count) }
              
        theBoard = Array(repeating: Array(repeating: 0, count: numCols), count: numRows)
        theScore = Array(repeating: Array(repeating: 0, count: numCols), count: numRows)
        gameStartTime = Date()
        lastScore = nil
        statusText = "Try to guess the hidden color code"
        
        // Now start the animation
        startCodeAnimation()
        
        print("🔐 SECRET CODE: \(theCode)")
        print("🏁 startGame(): DecodeGame initialized with scoreManager: \(type(of: scoreManager))")
    }
    
    //USED WHEN THEN HOW TO PLAY DIALOG IS UP
    func startGameWithoutAnimation() {
        isAnimating = false
        gameInteractive = false
        
        pegShades = [myPegColor1, myPegColor2, myPegColor3, myPegColor4, myPegColor5, myPegColor6]
        currentTurn = 0
        gameOver = 0
        
        theCode = (0..<numCols).map { _ in Int.random(in: 1..<pegShades.count) }
        
        theBoard = Array(repeating: Array(repeating: 0, count: numCols), count: numRows)
        theScore = Array(repeating: Array(repeating: 0, count: numCols), count: numRows)
        gameStartTime = Date()
        lastScore = nil
                
        animatedCode = (0..<numCols).map { _ in 0 }
        
        print("🔐 SECRET CODE: \(theCode)")
        print("🏁 startGameWithoutAnimation(): DecodeGame initialized with scoreManager: \(type(of: scoreManager))")
    }

    
    func resetGame() {
        print("⚠️ calling resetGame()")
        startGame()
    }
    
    func startCodeAnimation() {
        isAnimating = true
        gameInteractive = false
        animationStartTime = Date()
        
        // Initialize animated code with random colors
        animatedCode = (0..<numCols).map { _ in Int.random(in: 1..<pegShades.count) }
        
        // Start the animation timer
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] timer in
            self?.updateAnimation()
        }
    }
    
    func updateAnimation() {
        guard let startTime = animationStartTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let totalDuration: TimeInterval = 2.2
        let fastPhase: TimeInterval = 1.8
        
        if elapsed < fastPhase {
            // Fast shuffling phase - update all colors randomly
            animatedCode = (0..<numCols).map { _ in Int.random(in: 1..<pegShades.count) }
        } else if elapsed < totalDuration {
            // Slower phase - reduce frequency of updates
            let slowPhaseProgress = (elapsed - fastPhase) / (totalDuration - fastPhase)
            let updateProbability = 1.0 - slowPhaseProgress * 0.8 // Gradually reduce update frequency
            
            for i in 0..<numCols {
                if Double.random(in: 0...1) < updateProbability {
                    animatedCode[i] = Int.random(in: 1..<pegShades.count)
                }
            }
        } else {
            // Animation complete
            completeAnimation()
        }
    }
    
    private func completeAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        
        // Transition to final gray state
        withAnimation(.easeOut(duration: 0.3)) {
            isAnimating = false
        }
        
        // Make game interactive after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeIn(duration: 0.2)) {
                self.gameInteractive = true
                // Only set status text if it's still the default or empty
                if self.statusText.isEmpty || self.statusText == "Learn how to play, then start cracking the code!" {
                    self.statusText = "Tap each square to assign a color."
                }
            }
        }
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
        guard row == currentTurn, gameOver == 0 else {
            print("scoreRow rejected: row=\(row), currentTurn=\(currentTurn), gameOver=\(gameOver)")
            return
        }
        
        print("scoreRow executing for turn \(row)")
        
        if checkRow(row) {
            // DEBUG: Print the current guess vs the code
            print("🎯 GUESS \(row + 1): \(theBoard[row]) vs CODE: \(theCode)")
            
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

            // DEBUG: Print the scoring results
            print("📊 SCORING: \(exactMatches) exact matches, \(partialMatches) partial matches for row index \(row)")

            // Set score indicators
            for col in 0..<exactMatches { theScore[row][col] = 2 } // Green dots
            for col in exactMatches..<(exactMatches + partialMatches) { theScore[row][col] = 1 } // Yellow dots

            statusText = "You got \(exactMatches) color\(exactMatches == 1 ? " " : "s ")in the RIGHT spot.\n\nYou got \(partialMatches) color\(partialMatches == 1 ? " " : "s ")in the WRONG spot.\n\nTry again."
            
            // Check win condition
            if exactMatches == numCols {
                print("🎉 WIN DETECTED! Setting gameOver = 1")
                gameOver = 1
                statusText = "You cracked the code! Nice job!"
                saveGameScore(won: true)
                
                if let score = lastScore {
                    statusText += "\n\nScore: \(score.finalScore) points"
                    statusText += "\nTime: \(score.formattedTime)"
                    statusText += "\nAttempts: \(score.attempts)"
                }
                return
            }

            // Only increment currentTurn if the game wasn't won
            currentTurn += 1
            print("➡️ Moving to try # \(currentTurn + 1) -- currentTurn index is: \(currentTurn)")

            // Check lose condition (out of attempts)
            if currentTurn >= numRows {
                print("💀 GAME OVER! No more turns")
                gameOver = 1
                statusText = "Sorry, you're out of guesses. Maybe next time!"
                currentTurn = currentTurn - 1 //reset to pass the right information to GameScore and EndGame
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
        let attempts = currentTurn + 1
        
        let finalScore = GameScoreManager.calculateDecodeScore(
            attempts: attempts,
            timeElapsed: timeElapsed,
            won: won,
            maxAttempts: numRows
        )

        print("Saving game score: \(finalScore) points, won: \(won), attempts: \(attempts)")
        
        scoreManager.saveDecodeScore(
            attempts: attempts,
            timeElapsed: timeElapsed,
            won: won,
            finalScore: finalScore,
            turnsToSolve: attempts,
            codeLength: numCols
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.lastScore = self.scoreManager.getMostRecentScore(for: "decode")
        }
        
        print("Score saved successfully to \(type(of: scoreManager))")
    }

    func getRecentScores() -> [GameScore] {
        return scoreManager.getScores(for: "decode")
    }

    
    deinit {
        animationTimer?.invalidate()
    }
    
    
}
