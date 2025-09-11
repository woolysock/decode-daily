import SwiftUI

struct HowToPlayOverlay: View {
    let gameID: String
    let instructions: String
    @Binding var isVisible: Bool
    
    @State private var dontShowAgain: Bool = false
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    dismissOverlay()
                }
            
            // Main instruction card
            VStack(alignment: .center, spacing: 20) {
                
                Text("How to Play")
                    .font(.custom("LuloOne-Bold", size: 26))
                    .bold()
                    .foregroundColor(.white)
                
                ScrollView {
                    Text(instructions)
                        .font(.custom("SoleilLt", size: gameID != "decode" ? 20 : 19))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxHeight: gameID != "decode" ? 330 : 350)
                
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
                
                Toggle("do not show again", isOn: $dontShowAgain)
                    .foregroundColor(.myAccentColor1)
                    //.background(.white.opacity(0.1))
                    .font(.custom("LuloOne-Bold", size: 14))
                    .shadow(radius: 3)
                    .onChange(of: dontShowAgain) {
                        UserDefaults.standard.set(dontShowAgain, forKey: "hasSeenHowToPlay_\(gameID)")
                    }
                
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 40)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white, lineWidth: 0.5)
            )
            .background(Color.myOverlaysColor)
            .cornerRadius(16)
            .contentShape(Rectangle())
            .onTapGesture {
                dismissOverlay()
            }
            .onAppear {
                // Sync toggle state with saved setting on appear
                let savedValue = UserDefaults.standard.bool(forKey: "hasSeenHowToPlay_\(gameID)")
                dontShowAgain = savedValue
            }
            .padding(30)
        }
    }
    
    private func dismissOverlay() {
        withAnimation {
            isVisible = false
        }
    }
}
