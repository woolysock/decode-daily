import SwiftUI

struct HowToPlayOverlay: View {
    let gameID: String
    let instructions: String
    @Binding var isVisible: Bool
    
    @State private var dontShowAgain: Bool = false
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    dismissOverlay()
                }
            
            // Main instruction card
            VStack(spacing: 20) {
                Spacer().frame(height: 10)
                
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
                    .onChange(of: dontShowAgain) {
                        UserDefaults.standard.set(dontShowAgain, forKey: "hasSeenHowToPlay_\(gameID)")
                    }

                
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
            .background(Color.myAccentColor2)
            .cornerRadius(16)
            .padding(30)
            .contentShape(Rectangle())
            .onTapGesture {
                dismissOverlay()
            }
            .onAppear {
                // Sync toggle state with saved setting on appear
                let savedValue = UserDefaults.standard.bool(forKey: "hasSeenHowToPlay_\(gameID)")
                dontShowAgain = savedValue
            }
        }
    }
    
    private func dismissOverlay() {
        withAnimation {
            isVisible = false
        }
    }
}
