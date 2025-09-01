//
//  AnagramsGameView.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/12/25.
//

import SwiftUI
import Combine

struct AnagramsGameView: View {
    let targetDate: Date?
    
    @ObservedObject private var wordsetManager = DailyWordsetManager.shared

    @EnvironmentObject var scoreManager: GameScoreManager
    @Environment(\.dismiss) private var dismiss

    @StateObject private var game = GameContainer()
    @StateObject private var dailyCheckManager = DailyCheckManager.shared

    @State private var showHowToPlay = false
    @State private var showEndGameOverlay = false
    @State private var hasStartedRound = false
    @State private var navigateToHighScores = false
    @State private var answerFlashColor: Color? = nil
    
    private let instructionsText = """
    Race against the clock to unscramble as many words as you can!
    
    Each day brings a fresh set of words to challenge you. Tap a letter to spell out the correct word in the boxes above.
    
    O R W D  →  W O R D 

    If you make a mistake, tap "clear" to remove the letters and try again. 
    """
    
    init(targetDate: Date? = nil) {
        self.targetDate = targetDate
    }
    
    var body: some View {
        ZStack {
            NavigationStack {
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    Group {
                        if let anagramsGame = game.anagramsGame {
                            gameContent(with: anagramsGame)
                        } else {
                            ProgressView("Loading game...")
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(2.0)
                        }
                    }
                    .onAppear {
                        initializeGame()
                    }
                }
                .navigationDestination(isPresented: $navigateToHighScores) {
                    if let anagramsGame = game.anagramsGame {
                        MultiGameLeaderboardView(selectedGameID: anagramsGame.gameInfo.id)
                    }
                }
            }
            
            // Move overlays outside NavigationStack to root ZStack level
            if let anagramsGame = game.anagramsGame {
                if showEndGameOverlay {
                    EndGameOverlay(
                        gameID: anagramsGame.gameInfo.id,
                        finalScore: anagramsGame.lastScore?.finalScore ?? anagramsGame.attempts,
                        displayName: anagramsGame.gameInfo.displayName,
                        isVisible: $showEndGameOverlay,
                        onPlayAgain: { startNewGame() },
                        onHighScores: { navigateToHighScores = true },
                        onMenu: {
                            showEndGameOverlay = false
                            dismiss()
                        },
                        gameScore: anagramsGame.lastScore
                    )
                    .transition(.opacity)
                }

                if showHowToPlay {
                    GeometryReader { geometry in
                        HowToPlayOverlay(
                            gameID: anagramsGame.gameInfo.id,
                            instructions: instructionsText,
                            isVisible: $showHowToPlay
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    }
                    .ignoresSafeArea(.all)
                    .transition(.opacity)
                }
            }
        }
        .onChange(of: dailyCheckManager.showNewDayOverlay) { oldValue, newValue in
            guard let anagramsGame = game.anagramsGame else { return }
            
            // Only respond to new day overlay if this is NOT an archived game
            if targetDate == nil {
                if newValue {
                    // New day overlay is showing - force end the game immediately
                    print("AnagramsGameView: Force ending game due to new day overlay")
                    anagramsGame.endGame()
                    
                    // Hide any other overlays that might be showing
                    showEndGameOverlay = false
                    showHowToPlay = false
                    
                    // Reset the game state
                    hasStartedRound = false
                }
            }
        }

        // Also add this onChange to handle when the overlay is dismissed:
        .onChange(of: dailyCheckManager.showNewDayOverlay) { oldValue, newValue in
            // When overlay is dismissed (goes from true to false), return to main menu
            if targetDate == nil && oldValue == true && newValue == false {
                print("AnagramsGameView: New day overlay dismissed, returning to main menu")
                dismiss()
            }
        }
    }
    
    // MARK: - Initialization
    private func initializeGame() {
        print("🔧 Initializing game...")
        
        if game.anagramsGame == nil {
            game.anagramsGame = AnagramsGame(scoreManager: scoreManager, targetDate: targetDate)
        }
        
        print("📊 WordsetManager Status:")
        print("   - currentWordset: \(wordsetManager.currentWordset?.words.count ?? 0) words")
        print("   - isGeneratingWordsets: \(wordsetManager.isGeneratingWordsets)")
        
        // Show how to play or start game
        if UserDefaults.standard.bool(forKey: "hasSeenHowToPlay_anagrams") {
            // If we already have a wordset, start immediately
            if wordsetManager.currentWordset != nil && !wordsetManager.isGeneratingWordsets {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    tryToStartGame()
                }
            }
            // Otherwise, the onChange handler will start the game when the wordset loads
        } else {
            showHowToPlay = true
        }
    }
    
    private func tryToStartGame() {
        guard !hasStartedRound,
              let anagramsGame = game.anagramsGame,
              wordsetManager.currentWordset != nil,
              !wordsetManager.isGeneratingWordsets else {
            print("❌ tryToStartGame(): Cannot start - conditions not met")
            return
        }
        
        print("✅ tryToStartGame(): Starting game...")
        hasStartedRound = true
        anagramsGame.startGame()
    }
    
    @ViewBuilder
    private func gameContent(with anagramsGame: AnagramsGame) -> some View {
        
        //DEBUG TEXT
        //        let _ = print("🖥️ UI Update - gameContent called")
        //        let _ = print("   - isPreCountdownActive: \(anagramsGame.isPreCountdownActive)")
        //        let _ = print("   - isGameActive: \(anagramsGame.isGameActive)")
        //        let _ = print("   - countdownValue: \(anagramsGame.countdownValue)")
        //        let _ = print("   - statusText: '\(anagramsGame.statusText)'")
        
        VStack(spacing: 0) {
            Spacer().frame(height:10)
            
            // Title + Timer + Help button
            HStack {
                Spacer().frame(width: 5)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(anagramsGame.gameInfo.displayName)
                            .foregroundColor(.white)
                            .font(.custom("LuloOne-Bold", size: 20))
                            .onTapGesture { tryToStartGame() }
                        
                        // Archive indicator
                        if targetDate != nil {
                            Text("ARCHIVE")
                                .font(.custom("LuloOne", size: 8))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                                      
                    // Daily indicator
                    if let targetDate = targetDate {
                        //when launching from the archives
                        //let _ = print("... targetDate: \(targetDate.localStartOfDay)")
                        
                        Text(DateFormatter.dayStringFormatter.string(from: targetDate.localStartOfDay))
                            .font(.custom("LuloOne", size: 12))
                            .foregroundColor(.gray)
                    } else if let wordset = wordsetManager.currentWordset {
                        //when launching today's game from Main Menu & targetDate is nil
//                        let _ = print("... wordset.date: \(wordset.date)")
//                        let _ = print("... wordset.date.localStartOfDay: \(wordset.date.localStartOfDay)")
                        
                        Text(DateFormatter.dayStringFormatter.string(from: wordset.date))
                                .font(.custom("LuloOne", size: 12))
                                .foregroundColor(.gray)
//                        Text(DateFormatter.dayFormatter.string(from: wordset.date.localStartOfDay))
//                                .font(.custom("LuloOne", size: 12))
//                                .foregroundColor(.gray)
//                        Text(DateFormatter.day2Formatter.string(from: wordset.date.localStartOfDay))
//                                .font(.custom("LuloOne", size: 12))
//                                .foregroundColor(.gray)
//                        Text(DateFormatter.debugFormatter.string(from: wordset.date.localStartOfDay))
//                                .font(.custom("LuloOne", size: 12))
//                                .foregroundColor(.gray)
                    }
                }

                Spacer()

                // Top-center game clock
                Group {
                    if anagramsGame.isGameActive {
                        Text("\(anagramsGame.gameTimeRemaining)")
                            .font(.custom("LuloOne-Bold", size: 20))
                            .foregroundColor(.white)
                            .monospacedDigit()
                            .frame(minWidth: 54, alignment: .center)
                            .transition(.opacity)
                    } else {
                        Text(" ")
                            .font(.custom("LuloOne-Bold", size: 20))
                            .frame(minWidth: 54)
                            .opacity(0)
                    }
                }

                Spacer()

                Button { showHowToPlay = true } label: {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.white)
                        .font(.title2)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer().frame(height:5)
            
            Divider().background(.white).padding(5)
            
            Spacer().frame(height: 15)
            
            // Status text + symbol + wordset loading indicator
            VStack(spacing: 5) {
                if wordsetManager.isGeneratingWordsets {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        
                        Text("Loading today's words...")
                            .foregroundColor(.white)
                            .font(.custom("LuloOne", size: 12))
                    }
                } else {
                    Text(anagramsGame.statusText)
                        .foregroundColor(.white)
                        .font(.custom("LuloOne", size: 12))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 4)
                }

                if anagramsGame.statusText.contains("Wrong") {
                    Image(systemName: "wrongwaysign.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.red)
                } else if anagramsGame.statusText.contains("Correct"){
                    Image(systemName: "checkmark.seal.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color.myAccentColor1)
                } else if anagramsGame.statusText.contains("Tap"){
                    Image(systemName: "hand.tap.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(wordsetManager.isGeneratingWordsets ? .gray : .white)
                } else {
                    Image(systemName: "hare.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.clear)
                }
            }
            
            // === GAME BOARD ===
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 30) {
                    //let _ = print("🎮 UI Condition Check - isPreCountdownActive: \(anagramsGame.isPreCountdownActive), isGameActive: \(anagramsGame.isGameActive)")
                    
                    if anagramsGame.isPreCountdownActive {
                        //let _ = print("   → UI showing countdown")
                        Text("\(anagramsGame.countdownValue)")
                            .font(.custom("LuloOne-Bold", size: 100))
                            .foregroundColor(.white)
                            .monospacedDigit()
                            .scaleEffect(1.05)
                            .transition(.scale)
                    } else if anagramsGame.isGameActive {
                        //let _ = print("   → UI should show game area")
                        Spacer().frame(height:5)
                        gameArea(with: anagramsGame)
                        Spacer()
                    } else if wordsetManager.isGeneratingWordsets {
                        //let _ = print("   → UI showing wordset loading")
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(2.0)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            
                            Text("Preparing today's challenge...")
                                .font(.custom("LuloOne", size: 16))
                                .foregroundColor(.white)
                        }
                    } else {
                        //let _ = print("   → UI showing default state")
                        Spacer()
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding([.leading, .trailing, .bottom], 20)
            }
            
            Spacer()
        }
        // FIXED: Watch for wordset changes and try to start game
        .onChange(of: wordsetManager.currentWordset) { oldValue, newValue in
            print("📝 wordsetManager.currentWordset changed:")
            print("   - New wordset: \(newValue?.words.count ?? 0) words")
            print("   - hasStartedRound: \(hasStartedRound)")
            
            if !hasStartedRound && newValue != nil && !wordsetManager.isGeneratingWordsets {
                // If how-to-play is not showing, start the game
                if !showHowToPlay {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        tryToStartGame()
                    }
                }
            }
        }
        
        // FIXED: Watch for generation completion
        .onChange(of: wordsetManager.isGeneratingWordsets) { oldValue, newValue in
            print("📝 isGeneratingWordsets changed: \(oldValue) → \(newValue)")
            
            // If generation just finished and we have a wordset, try to start
            if oldValue == true && newValue == false &&
               !hasStartedRound &&
               wordsetManager.currentWordset != nil &&
               !showHowToPlay {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    tryToStartGame()
                }
            }
        }
        
        // UPDATED: Pause/resume game when overlay shows/hides
        .onChange(of: showHowToPlay, initial: false) { oldValue, newValue in
            if newValue {
                // Overlay is showing - pause the game
                anagramsGame.pauseGame()
            } else {
                // Overlay is hiding - resume the game
                anagramsGame.resumeGame()
                
                // Start game if conditions are right
                if !hasStartedRound &&
                   wordsetManager.currentWordset != nil &&
                   !wordsetManager.isGeneratingWordsets {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        tryToStartGame()
                    }
                }
            }
        }
        .onChange(of: anagramsGame.gameOver, initial: false) { oldValue, newValue in
            if newValue == 1 {
                showEndGameOverlay = true
            }
        }
        .onChange(of: anagramsGame.statusText) { oldValue, newValue in
            if newValue.contains("Correct") {
                flashAnswer(correct: true)
            } else if newValue.contains("Wrong") {
                flashAnswer(correct: false)
                
                // Delay clearing so the red flash is visible
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("Wrong answer detected")
                    anagramsGame.usedLetterIndices.removeAll()
                    anagramsGame.userAnswer = ""
                    //anagramsGame.statusText = "Try again."
                }
            }
        }
    }
    
    // MARK: - Letter Button
    private func letterButton(
        _ letter: String,
        isScrambled: Bool,
        isUsed: Bool,
        flashColor: Color? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(isUsed ? "" : letter)
                .font(.custom("LuloOne-Bold", size: 20))
                .foregroundColor(.black)
                .frame(width: isScrambled ? 60 : 35, height: isScrambled ? 60 : 35)
                .background(
                    (flashColor != nil ? flashColor! :
                        (isUsed ? Color.gray.opacity(0.3) :
                            (isScrambled ? Color.white : Color.myAccentColor1)))
                )
                .clipShape(isScrambled ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 5)))
                .overlay(
                    Group {
                        if isScrambled {
                            Circle().stroke(Color.myAccentColor1, lineWidth: 3)
                        } else {
                            RoundedRectangle(cornerRadius: 0).stroke(Color.black, lineWidth: 1)
                        }
                    }
                )
                .shadow(radius: isUsed ? 1 : 2)
                .animation(.easeInOut(duration: 0.3), value: flashColor)
        }
        .disabled(!game.anagramsGame!.isGameActive || game.anagramsGame!.isGamePaused || isUsed || wordsetManager.isGeneratingWordsets)
    }
    
    // MARK: - Scrambled Letters Grid
    private func scrambledLettersGrid(with anagramsGame: AnagramsGame) -> some View {
        let columns = Array(repeating: GridItem(.flexible(minimum: 50), spacing: 10), count: 4)
        
        return LazyVGrid(columns: columns, spacing: 10) { // vertical spacing = 10
            ForEach(0..<anagramsGame.scrambledLetters.count, id: \.self) { index in
                letterButton(
                    anagramsGame.scrambledLetters[index],
                    isScrambled: true,
                    isUsed: anagramsGame.usedLetterIndices.contains(index)
                ) {
                    anagramsGame.selectLetter(at: index)
                }
            }
        }
        .padding(.horizontal, 10)
    }
    
    // MARK: - Game Area
    private func gameArea(with anagramsGame: AnagramsGame) -> some View {
        VStack(spacing: 10) {
            if anagramsGame.isGameActive {
                
                HStack {
                    Text("Solved: \(anagramsGame.attempts)")
                        .font(.custom("LuloOne-Bold", size: 16))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Show progress through daily words
                    
                    if let wordset = wordsetManager.currentWordset {
                        Text("On word\n\(anagramsGame.currentWordIndex + 1) of \(wordset.words.count)")
                            .font(.custom("LuloOne", size: 12))
                            .foregroundColor(.white)
                    }
                }
                Divider().background(Color.myAccentColor1).padding(5)
            }
            
            Spacer().frame(height: 20)
            
            // User Answer Boxes
            VStack(spacing: 10) {
                Text("Your Answer:")
                    .font(.custom("LuloOne", size: 14))
                    .foregroundColor(.white)
                
                HStack(spacing: 5) {
                    ForEach(0..<anagramsGame.userAnswer.count, id: \.self) { index in
                        let letter = String(
                            anagramsGame.userAnswer[anagramsGame.userAnswer.index(anagramsGame.userAnswer.startIndex, offsetBy: index)]
                        )
                        letterButton(letter, isScrambled: false, isUsed: false, flashColor: answerFlashColor) {
                            anagramsGame.removeLetter(at: index)
                        }
                    }
                    
                    // Show empty boxes for remaining letters - make them smaller for long words
                    ForEach(anagramsGame.userAnswer.count..<anagramsGame.currentWord.count, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 35, height: 35)
                            .cornerRadius(0)
                    }
                }
                .frame(minHeight: 55)
                
                Button("erase") {
                    anagramsGame.clearAnswer()
                }
                .font(.custom("LuloOne", size: 12))
                .foregroundColor(anagramsGame.userAnswer.isEmpty ? .gray : .white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(anagramsGame.userAnswer.isEmpty ? Color.gray.opacity(0.3) : Color.pink.opacity(0.7))
                .cornerRadius(8)
                .disabled(anagramsGame.userAnswer.isEmpty || anagramsGame.isGamePaused || wordsetManager.isGeneratingWordsets)
            }
            
            Spacer().frame(height: 25)
            
            // Scrambled letters grid
            VStack(spacing: 10) {
                Text("Scrambled Letters:")
                    .font(.custom("LuloOne", size: 14))
                    .foregroundColor(.white)
                
                scrambledLettersGrid(with: anagramsGame)
            }
            
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Game Control Methods
    private func startNewGame() {
        guard let anagramsGame = game.anagramsGame else { return }
        showEndGameOverlay = false
        hasStartedRound = false
        
        // Reset game state
        anagramsGame.resetGame()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            tryToStartGame()
        }
    }
    
    // MARK: - Flash Answer
    private func flashAnswer(correct: Bool) {
        answerFlashColor = correct ? .green : .red
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            answerFlashColor = nil
        }
    }
    
  
}



// Container class to hold the AnagramsGame and make it properly observable
class GameContainer: ObservableObject {
    @Published var anagramsGame: AnagramsGame? {
        didSet {
            // When anagramsGame is set, forward its objectWillChange to our own
            anagramsGame?.objectWillChange.sink { [weak self] in
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                }
            }.store(in: &cancellables)
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
}

// Helper struct to allow both Circle and RoundedRectangle in clipShape
struct AnyShape: Shape {
    private let _path: @Sendable (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        _path = { rect in
            shape.path(in: rect)
        }
    }

    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}
