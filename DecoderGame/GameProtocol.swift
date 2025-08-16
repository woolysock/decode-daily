//
//  GameProtocol.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/14/25.
//

import SwiftUI

// Base protocol that all games must implement
protocol GameProtocol: ObservableObject {
    var gameOver: Int { get set }
    var statusText: String { get set }
    
    func startGame()
    func resetGame()
}

// Game metadata for menu display
struct GameInfo {
    let id: String
    let displayName: String
    let description: String
    let isAvailable: Bool
    
    static let availableGames: [GameInfo] = [
        GameInfo(id: "decode", displayName: "decode", description: "crack the color code", isAvailable: true),
        GameInfo(id: "flashdance", displayName: "flashdance", description: "math flash card fun", isAvailable: true),
        GameInfo(id: "numbers", displayName: "numbers", description: "solve the equations", isAvailable: true)
        // Future games can be added here:
        // GameInfo(id: "wordle", displayName: "Word Game", description: "Guess the word", isAvailable: false),
    ]
}
