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
    let gameLocation: AnyView
    let gameIcon: Image
    
    static let availableGames: [GameInfo] = [
        GameInfo(id: "decode", displayName: "decode", description: "crack the color code", isAvailable: true, gameLocation: AnyView(DecodeGameView()), gameIcon: Image(systemName: "moonphase.first.quarter")),
        GameInfo(id: "flashdance", displayName: "flashdance", description: "math flashcard fun", isAvailable: true, gameLocation: AnyView(FlashdanceGameView()), gameIcon: Image(systemName: "30.arrow.trianglehead.clockwise")),
        //GameInfo(id: "numbers", displayName: "numbers", description: "solve the equations", isAvailable: false, gameLocation: AnyView(NumbersGameView())),
        GameInfo(id: "anagrams", displayName: "letters", description: "rearrange letters into words", isAvailable: true, gameLocation: AnyView(AnagramsGameView()), gameIcon: Image(systemName: "60.arrow.trianglehead.clockwise"))
    ]

}
