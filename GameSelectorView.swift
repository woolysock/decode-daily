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
        .padding(.vertical, 5)
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
                .frame(width: 70, height: 35)
                .font(.custom("LuloOne-Bold", size: sizeCategory > .medium ? 10 : 12))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .minimumScaleFactor(sizeCategory > .medium ? 0.7 : 1.0)
                .lineLimit(2) //, reservesSpace: true)
                .allowsTightening(true)
                .multilineTextAlignment(.center)
                .background(isSelected ? Color.white : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: sizeCategory > .large ? 3 : 2)
                        .background(.clear)
                )
                .cornerRadius(8)
        }
        //.padding(4)
    }
}
