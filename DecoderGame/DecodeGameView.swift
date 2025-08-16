//
//  DecodeGameView.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/14/25.
//

import SwiftUI

struct DecodeGameView: View {
    @ObservedObject var game = DecodeGame()
    
    // Color picker state
    @State private var showingColorPicker = false
    @State private var colorPickerPosition = CGPoint.zero
    @State private var selectedSquare: (row: Int, col: Int) = (0, 0)
    @State private var pickerSize: CGSize = .zero
    @State private var frameOffset: CGPoint = .zero

    // How-to-play overlay state
    @State private var showHowToPlay = false
    
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 15) {
                // Title + How To Play button
                HStack {
                    Text("decode")
                        .foregroundColor(.white)
                        .font(.custom("LuloOne-Bold", size: 20))
                        .onTapGesture {
                            game.startGame()
                        }
                    
                    Spacer()
                    
                    Button(action: {
                        showHowToPlay = true
                    }) {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                }
                .padding(.horizontal, 20)

                Divider().background(.white).padding(5)
                
                // Code display
                HStack(spacing: 10) {
                    ForEach(0..<game.numCols, id: \.self) { col in
                        Rectangle()
                            .frame(width: 40, height: 40)
                            .foregroundColor(game.gameOver != 0 ? game.pegShades[game.theCode[col]] : game.myPegColor1)
                            .overlay(
                                Text("?")
                                    .font(.custom("LuloOne-Bold", size: 14))
                                    .foregroundColor(game.gameOver == 0 ? .white : .clear)
                            )
                    }
                }
                
                // Status text
                Rectangle()
                    .frame(width: 300, height: game.gameOver != 0 && game.lastScore != nil ? 120 : 60)
                    .foregroundColor(.clear)
                    .overlay(
                        Text(game.statusText)
                            .font(.custom("LuloOne", size: game.gameOver != 0 && game.lastScore != nil ? 10 : 8))
                            .foregroundColor(.white)
                            .lineSpacing(3)
                            .multilineTextAlignment(.center)
                            .padding(8)
                    )
                
                Divider().background(.white).padding(5)
                
                // Game board
                VStack(spacing: 10) {
                    ForEach(0..<game.numRows, id: \.self) { row in
                        HStack(spacing: 10) {
                            ForEach(0..<game.numCols, id: \.self) { col in
                                let currentColor = game.pegShades[game.theBoard[row][col]]
                                
                                Rectangle()
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(1)
                                    .foregroundColor(
                                        game.gameOver == 0
                                        ? (row <= game.currentTurn ? currentColor : .clear)
                                        : (row != game.currentTurn - 1 ? currentColor.opacity(0.6) : currentColor)
                                    )
                                    .contentShape(Rectangle())
                                    .overlay(
                                        GeometryReader { geometry in
                                            Color.clear
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    guard row == game.currentTurn else {
                                                        if row > game.currentTurn { game.theBoard[row][col] = 0 }
                                                        return
                                                    }
                                                    
                                                    selectedSquare = (row: row, col: col)
                                                    
                                                    // Frame relative to the board coordinate space
                                                    let frame = geometry.frame(in: .named("GameBoardSpace"))
                                                    // Frame relative to the screen
                                                    let screenFrame = geometry.frame(in: .global)
                                                    
                                                    frameOffset = CGPoint(
                                                        x: screenFrame.midX - frame.midX,
                                                        y: screenFrame.midY - frame.midY
                                                    )

//                                                    print("GameBoardSpace frame: midX=\(frame.midX), midY=\(frame.midY)")
//                                                    print("Screen frame: midX=\(screenFrame.midX), midY=\(screenFrame.midY)")
//                                                    print("Offsets: x=\(frameOffset.x), y=\(frameOffset.y)")
                                                    
                                                    // Use GameBoardSpace coordinates for picker
                                                    colorPickerPosition = CGPoint(x: screenFrame.midX, y: screenFrame.midY - frame.height - 34)
                                                    
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                        showingColorPicker = true
                                                    }
                                                    
                                                    game.statusText = "Choose a color for this square."
                                                   // print("Tapped square \(row),\(col) -> picker offset \(colorPickerPosition) & frame.height = \(frame.height)")
                                                }
                                                .allowsHitTesting(!showingColorPicker && !showHowToPlay)
                                        }
                                    )

                            }
                            
                            // Spacer before score button
                            Rectangle().frame(width: 10, height: 10).foregroundColor(.clear)
                            
                            // Score indicators
                            ZStack {
                                VStack {
                                    HStack {
                                        Circle()
                                            .frame(width: 10, height: 10)
                                            .foregroundColor(row < game.currentTurn ? game.scoreShades[game.theScore[row][0]] : .clear)
                                        Circle()
                                            .frame(width: 10, height: 10)
                                            .foregroundColor(row < game.currentTurn ? game.scoreShades[game.theScore[row][1]] : .clear)
                                    }
                                    HStack {
                                        Circle()
                                            .frame(width: 10, height: 10)
                                            .foregroundColor(row < game.currentTurn ? game.scoreShades[game.theScore[row][2]] : .clear)
                                        Circle()
                                            .frame(width: 10, height: 10)
                                            .foregroundColor(row < game.currentTurn ? game.scoreShades[game.theScore[row][3]] : .clear)
                                    }
                                }
                                
                                // Circle that submits the score
                                Circle()
                                    .frame(width: 50)
                                    .foregroundColor(row == game.currentTurn ? (game.gameOver == 0 ? .gray : .clear) : .clear)
                                    .contentShape(Circle())
                                    .onTapGesture {
                                        if row == game.currentTurn { game.scoreRow(row) }
                                    }
                            }
                        }
                    }
                }
                .coordinateSpace(name: "GameBoardSpace") // board space for picker alignment
            }
            
            // Color Picker Overlay
            if showingColorPicker {
                ColorPickerOverlay(
                    showingPicker: $showingColorPicker,
                    pickerPosition: $colorPickerPosition,
                    colors: Array(game.pegShades.dropFirst()),
                    onColorSelected: { colorIndex in
                        let gameColorIndex = colorIndex + 1
                        game.theBoard[selectedSquare.row][selectedSquare.col] = gameColorIndex
                        game.statusText = "Tap the circle when you're ready to submit a guess."
                    }
                )
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: SizePreferenceKey.self, value: geo.size)
                    }
                )
                .zIndex(1)
            }
            // How-to-Play Overlay
            if showHowToPlay {
                HowToPlayOverlay(
                    gameID: "decodeGame",
                    instructions: """
                    The goal is to crack the secret color code! 
                    \n\nEach turn:
                    \nTap a square to assign a color.
                    Tap the circle to check if your guess is right!
                    \n ▢ ▢ ▢ ▢ ▢  ➜   ⃝ 
                    \nHint dots will guide you:
                      \nGreen ● for every correct color, correct spot
                      \nYellow ● for every correct color, wrong spot
                    \n\nCan you figure it out?
                    """,
                    isVisible: $showHowToPlay
                )
                .transition(.opacity)
                .zIndex(2)
            }
        }

        .onAppear {
            // Show the How-to-Play overlay if the user hasn't dismissed it before
            let key = "hasSeenHowToPlay_decodeGame"
            if !UserDefaults.standard.bool(forKey: key) {
                showHowToPlay = true
            }
        }
    }
    
    struct SizePreferenceKey: PreferenceKey {
        static var defaultValue: CGSize = .zero
        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
            value = nextValue()
        }
    }
    
    // Legacy compatibility - keep this for now so existing navigation doesn't break
    typealias GameView = DecodeGameView
}
