//
//  ColorPickerOverlay.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/14/25.
//

import SwiftUI

struct ColorPickerOverlay: View {
    @Binding var showingPicker: Bool
    @Binding var pickerPosition: CGPoint
    let colors: [Color]
    let onColorSelected: (Int) -> Void
    
    // Picker layout constants
    private let maxRadius: CGFloat = 60
    private let circleSize: CGFloat = 60
    
    var body: some View {
        if showingPicker {
            GeometryReader { geo in
                ZStack {
                    // Background to dismiss
                    Color.black.opacity(0.1)
                        .ignoresSafeArea()
                        .onTapGesture { showingPicker = false }
                    
                    // Picker circles
                    ZStack {
                        let adjustedCenter = computeAdjustedCenter(geo: geo)
                        
                        ForEach(0..<min(colors.count, 5), id: \.self) { index in
                            let angleStep = 360.0 / Double(min(colors.count, 5))
                            let angle = Double(index) * angleStep * .pi / 180
                            
                            let xOffset = maxRadius * cos(angle - .pi / 2)
                            let yOffset = maxRadius * sin(angle - .pi / 2)
                            
                            ColorCircle(
                                color: colors[index],
                                colorIndex: index
                            ) { colorIndex in
                                onColorSelected(colorIndex)
                                showingPicker = false
                            }
                            .position(
                                x: adjustedCenter.x + xOffset,
                                y: adjustedCenter.y + yOffset
                            )
                        }
                    }
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.8)))
            .zIndex(1000)
        }
    }
    
    // Compute the adjusted picker center to ensure the whole picker is onscreen
    private func computeAdjustedCenter(geo: GeometryProxy) -> CGPoint {
        let totalRadius = maxRadius + circleSize / 2
        
        var x = pickerPosition.x
        var y = pickerPosition.y
        
        // Clamp horizontally
        if x - totalRadius < 0 { x = totalRadius }
        if x + totalRadius > geo.size.width { x = geo.size.width - totalRadius }
        
        // Clamp vertically
        if y - totalRadius < 0 { y = totalRadius }
        if y + totalRadius > geo.size.height { y = geo.size.height - totalRadius }
        
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Single Circle
struct ColorCircle: View {
    let color: Color
    let colorIndex: Int
    let onColorSelected: (Int) -> Void
    
    @State private var isSelected = false
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: isSelected ? 70 : 60,
                   height: isSelected ? 70 : 60)
            .shadow(color: .black.opacity(0.4),
                    radius: 6, x: 0, y: 3)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .onTapGesture { select() }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isSelected {
                            isSelected = true
                            hapticFeedback()
                        }
                    }
                    .onEnded { _ in
                        select()
                    }
            )
            .animation(.spring(response: 0.3,
                               dampingFraction: 0.7),
                       value: isSelected)
    }
    
    private func select() {
        hapticFeedback()
        isSelected = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            onColorSelected(colorIndex)
        }
    }
    
    private func hapticFeedback() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
}
