import SwiftUI

struct FlashdanceGameView: View {
    @ObservedObject var game = FlashdanceGame()
    
    @State private var showHowToPlay = false
    
    // Instructions specific to Flashdance
    private let instructionsText = """
    Flashdance is a quick-moving race against the clock to solve the most math problems.
    
    You’ll be shown series of math equation flashcards.
    + - × ÷

    Swipe each card towards the correct answer, before time runs out.
    ⇠ ⇡ ⇢
    
    The more flashcards you solve, the higher you score!
    
    
    { Restart any time by tapping the game title. }
    """
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 15) {
                // Title + How To Play button
                HStack {
                    Text("flashdance")
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
                
                // Status text
                Text(game.statusText)
                    .foregroundColor(.white)
                    .font(.custom("LuloOne", size: 12))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Spacer()
                
                ZStack{
                    Color.myAccentColor1
                        .ignoresSafeArea()
                    ZStack{
                        // Placeholder content area
                        Color.white
                            .ignoresSafeArea()
                        // Placeholder content that should be fed in from an external data store
                        Text("1 + 1")
                            .foregroundColor(.black)
                            .font(.custom("LuloOne-Bold", size:64))
                    }
                    .padding([.leading, .trailing, .bottom], 20)
                }
               // .padding(20)
            }
            
            // Overlay
            if showHowToPlay {
                HowToPlayOverlay(
                    gameID: "flashdance",
                    instructions: instructionsText,
                    isVisible: $showHowToPlay
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            // Auto-show the first time unless "Don't show again" is checked
            if !UserDefaults.standard.bool(forKey: "hasSeenHowToPlay_flashdance") {
                withAnimation {
                    showHowToPlay = true
                }
            }
        }
    }
}
