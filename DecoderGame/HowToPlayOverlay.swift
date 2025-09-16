import SwiftUI

struct HowToPlayOverlay: View {
    let gameID: String
    let instructions: String
    @Binding var isVisible: Bool
    
    @State private var dontShowAgain: Bool = false
    @State private var isScrollable = false
    @Environment(\.sizeCategory) var sizeCategory
    
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
                    .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .allowsTightening(true)
                
                ScrollView(.vertical, showsIndicators: true) {
                    Text(instructions)
                        .font(.custom("SoleilLt", size: 18))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .allowsTightening(true)
                        .padding(10)
                        .background(
                            GeometryReader { textGeometry in
                                Color.clear
                                    .onAppear {
                                        checkScrollability(contentHeight: textGeometry.size.height)
                                    }
                                    .onChange(of: instructions) {
                                        checkScrollability(contentHeight: textGeometry.size.height)
                                    }
                                    .onChange(of: sizeCategory) {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            checkScrollability(contentHeight: textGeometry.size.height)
                                        }
                                    }
                            }
                        )
                }
                .frame(maxHeight: 350)
                .background(
                    // Different colors based on scroll state
                    isScrollable ?
                    Color.myAccentColor1.opacity(0.2) :  // Scrollable
                    Color.myAccentColor1.opacity(0.4)    // Fits without scrolling
                )
                .scrollIndicators(.visible)
                
                // Rest of your code remains the same...
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
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                }
                
                Toggle("do not show again", isOn: $dontShowAgain)
                    .foregroundColor(.myAccentColor1)
                    .font(.custom("LuloOne-Bold", size: 14))
                    .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                    .lineLimit(1)
                    .allowsTightening(true)
                    .shadow(radius: 3)
                    .onChange(of: dontShowAgain) {
                        UserDefaults.standard.set(dontShowAgain, forKey: "hasSeenHowToPlay_\(gameID)")
                    }
            }
            .padding(.horizontal, 20)
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
                let savedValue = UserDefaults.standard.bool(forKey: "hasSeenHowToPlay_\(gameID)")
                dontShowAgain = savedValue
                let _ = print("📲 sizeCategory: \(sizeCategory)")
            }
            .padding(sizeCategory > .medium  ? 15 : 30)
        }
    }
    
    private func checkScrollability(contentHeight: CGFloat) {
        // Account for padding (10 top + 10 bottom = 20)
        let availableHeight: CGFloat = 350 - 20
        isScrollable = contentHeight > availableHeight
    }
    
    private func dismissOverlay() {
        withAnimation {
            isVisible = false
        }
    }
}
