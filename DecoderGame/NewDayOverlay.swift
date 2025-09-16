//
//  NewDayOverlay.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/28/25.
//

import SwiftUI

struct NewDayOverlay: View {
    @Environment(\.sizeCategory) var sizeCategory
    
    @Binding var isVisible: Bool
    let onLetsPlay: () -> Void
    
    // Button activation delay (similar to EndGameOverlay)
    @State private var buttonsAreActive: Bool = false
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Rectangle()
                .fill(Color.black.opacity(0.8))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all)
                // Note: No tap gesture - user must tap the button
            
            // Main content card
            VStack(spacing: 25) {
                // Header
                VStack(spacing: 10) {
                    Text("It's a new day!")
                        .font(.custom("LuloOne-Bold", size: 28))
                        .foregroundColor(.white)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(2)
                        .allowsTightening(true)
                        .multilineTextAlignment(.center)
                    
                    Text("Fresh dailies await")
                        .font(.custom("LuloOne", size: sizeCategory > .medium ? 13 : 15))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                }
                
                Divider()
                    .background(.white)
                    .padding(.horizontal, 40)
                
                // Sunrise/new day icon
                VStack(spacing: 15) {
                    Image(systemName: "sun.horizon.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color.mySunColor)
                        .symbolRenderingMode(.hierarchical)
                    
                    Text("Play the challenges for \(DateFormatter.day2Formatter.string(from: Date()))!")
                        .font(.custom("LuloOne", size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(2)
                        .allowsTightening(true)
                }
                
                Divider()
                    .background(.white)
                    .padding(.horizontal, 40)
                
                // Action button
                Button("Let's Play!") {
                    dismiss()
                }
                .font(.custom("LuloOne-Bold", size: 18))
                .foregroundColor(buttonsAreActive ? .black : .gray)
                .frame(width: sizeCategory > .large ? 240 : 200, height: 50)
                .padding(.horizontal, 5)
                .background(buttonsAreActive ? Color.white : Color.gray.opacity(0.4))
                .cornerRadius(10)
                .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                .lineLimit(1)
                .allowsTightening(true)
                .disabled(!buttonsAreActive)
                .animation(.easeInOut(duration: 0.3), value: buttonsAreActive)
            }
            .padding(30)
            .background(Color.myOverlaysColor)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 40)
        }
        .onAppear {
            startActivationSequence()
        }
        .onChange(of: isVisible) { oldValue, newValue in
            if newValue {
                startActivationSequence()
            }
        }
    }
    
    private func startActivationSequence() {
        // Reset button state
        buttonsAreActive = false
        
        // Activate button after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            buttonsAreActive = true
        }
    }
    
    private func dismiss() {
        isVisible = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onLetsPlay()
        }
    }
}
