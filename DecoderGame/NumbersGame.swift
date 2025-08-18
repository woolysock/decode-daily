//
//  NumbersGame.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/14/25.
//

import SwiftUI

class NumbersGame: GameProtocol {
    @Published var gameOver: Int = 0
    @Published var statusText: String = "Numbers game coming soon! This is a placeholder for now."
    
    // Numbers-specific properties (placeholder for future implementation)
    @Published var currentNumber: Int = 0
    @Published var targetNumber: Int = 0
    @Published var attempts: Int = 0
    
    let maxAttempts = 6 // Example game configuration
    
    let gameInfo = GameInfo(
        id: "numbers",
        displayName: "numbers",
        description: "tbd",
        isAvailable: false,
        gameLocation: AnyView(NumbersGameView()),
        gameIcon: Image(systemName: "30.arrow.trianglehead.clockwise")
    )
    
    init() {
        startGame()
    }
    
    func startGame() {
        gameOver = 0
        currentNumber = 0
        targetNumber = Int.random(in: 1...100) // Example: guess a number 1-100
        attempts = 0
        statusText = "Numbers game initialized. Ready to play!"
    }
    
    func resetGame() {
        startGame()
    }
    
    // Placeholder for future game logic methods
    func makeGuess(_ guess: Int) {
        // Future implementation for number guessing logic
        attempts += 1
        
        if guess == targetNumber {
            gameOver = 1
            statusText = "Congratulations! You found the number!"
        } else if attempts >= maxAttempts {
            gameOver = 1
            statusText = "Game over! The number was \(targetNumber)"
        } else if guess < targetNumber {
            statusText = "Higher! \(maxAttempts - attempts) attempts left"
        } else {
            statusText = "Lower! \(maxAttempts - attempts) attempts left"
        }
    }
}
