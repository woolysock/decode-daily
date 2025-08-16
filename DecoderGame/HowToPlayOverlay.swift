import SwiftUI

struct HowToPlayOverlay: View {
    let gameID: String
    let instructions: String
    @Binding var isVisible: Bool
    
    @State private var dontShowAgain = false
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // Tap outside solid rectangle dismisses
                    dismissOverlay()
                }
            
            // Main instruction card
            VStack(spacing: 20) {
                Spacer()
                        .frame(height: 10)
                Text("How to Play")
                    .font(.custom("LuloOne-Bold", size: 22))
                    .bold()
                    .foregroundColor(.white)
                
                ScrollView {
                    Text(instructions)
                        .font(.custom("LuloOne", size: 12))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .frame(maxHeight: 300)
                
                Toggle("do not show again", isOn: $dontShowAgain)
                    .foregroundColor(.white).opacity(0.6)
                    .font(.custom("LuloOne-Bold", size: 12))
                    .padding(.horizontal)
                
                Button(action: {
                    dismissOverlay()
                }) {
                    Text("Got it!")
                        .font(.custom("LuloOne-Bold", size: 18))
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color.myAccentColor2) // Solid rectangle
            .cornerRadius(16)
            .padding(30)
            // Tap gesture on the solid rectangle dismisses overlay except for the toggle
            .contentShape(Rectangle())
            .onTapGesture {
                dismissOverlay()
            }
        }
    }
    
    private func dismissOverlay() {
        if dontShowAgain {
            UserDefaults.standard.set(true, forKey: "hasSeenHowToPlay_\(gameID)")
        }
        withAnimation {
            isVisible = false
        }
    }
}
