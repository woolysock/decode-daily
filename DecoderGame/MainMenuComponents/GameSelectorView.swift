//
//  GameSelectorView.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 9/15/25.
//


//
//  GameSelectorView.swift
//  Decode! Daily iOS
//
//  Created by Assistant on 9/15/25.
//

import SwiftUI

struct GameSelectorView: View {
    @Environment(\.sizeCategory) var sizeCategory
    @Binding var selectedArchiveGame: String
    
    var body: some View {
        HStack(spacing: 10) {
            GameSelectorButton(
                title: "Decode",
                gameId: "decode",
                selectedGame: $selectedArchiveGame
            )
            
            GameSelectorButton(
                title: "Flash\ndance",
                gameId: "flashdance",
                selectedGame: $selectedArchiveGame
            )
            
            GameSelectorButton(
                title: "'Grams",
                gameId: "anagrams",
                selectedGame: $selectedArchiveGame
            )
        }
        .padding(10)
    }
}

struct GameSelectorButton: View {
    @Environment(\.sizeCategory) var sizeCategory
    let title: String
    let gameId: String
    @Binding var selectedGame: String
    
    var isSelected: Bool {
        selectedGame == gameId
    }
    
    var body: some View {
        Button(action: {
            selectedGame = gameId
        }) {
            Text(title)
                .font(.custom("LuloOne-Bold", size: 11))
                .foregroundColor(isSelected ? .black : .white)
                
                .padding(.horizontal, sizeCategory > .medium ? 14 : 18)
                .padding(.vertical, sizeCategory > .medium ? 10 : 14)
                .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                .lineLimit(2)
                .allowsTightening(true)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: 1)
                )
                .cornerRadius(8)
                .background(isSelected ? Color.white : Color.clear)
        }
        .frame(width: 100, height: sizeCategory > .large ? 70 : 50)
    }
}
