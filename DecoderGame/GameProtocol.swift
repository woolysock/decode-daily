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
    var gameInfo: GameInfo { get }
    func startGame()
    func resetGame()
}

// Game metadata for menu display
struct GameInfo {
    let id: String
    let displayName: String
    let description: String
    let isAvailable: Bool
    let gameIcon: Image
    // Removed gameLocation entirely
    
    static let availableGames: [GameInfo] = [
        GameInfo(id: "decode", displayName: "Decode", description: "crack the color code", isAvailable: true, gameIcon: Image(systemName: "circle.hexagonpath")),
        GameInfo(id: "flashdance", displayName: "Flashdance", description: "math flashcard fun", isAvailable: true, gameIcon: Image(systemName: "30.arrow.trianglehead.clockwise")),
        //GameInfo(id: "numbers", displayName: "numbers", description: "solve the equations", isAvailable: false, gameIcon: Image(systemName: "number.circle")),
        GameInfo(id: "anagrams", displayName: "'Grams", description: "unscramble the letters", isAvailable: true, gameIcon: Image(systemName: "60.arrow.trianglehead.clockwise"))
    ]
}
