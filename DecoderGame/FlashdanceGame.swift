//
//  FlashdanceGame.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/15/25.
//

import SwiftUI

class FlashdanceGame: GameProtocol {
    @Published var gameOver: Int = 0
    @Published var statusText: String = "Flashdance game coming soon! This is a placeholder for now."
    
    // Numbers-specific properties (placeholder for future implementation)
    @Published var currentNumber: Int = 0
    @Published var targetNumber: Int = 0
    @Published var attempts: Int = 0

    init() {
        startGame()
    }

    func startGame() {
        gameOver = 0
        currentNumber = 0
        targetNumber = Int.random(in: 1...100) // Example: guess a number 1-100
        attempts = 0
        //statusText = "Flashdance game initialized. Ready to play!"
    }
    
    func resetGame() {
        startGame()
    }
    
}
