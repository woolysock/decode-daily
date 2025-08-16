// // ColorPickerView.swift // Decode! Daily iOS // // Created by Megan Donahue on 8/14/25. //

import SwiftUI

struct ColorPickerView: View {
    let colors: [Color]
    let onColorSelected: (Int) -> Void
    let onDismiss: () -> Void
    
    @State private var selectedColorIndex: Int? = nil
    
    var body: some View {
        ZStack {
            // Invisible background to catch taps outside picker
            
            Color.clear
                .ignoresSafeArea()   // fills the entire screen including safe areas
                .contentShape(Rectangle())
                .onTapGesture {
                    onDismiss()
                }
            // Color picker circles arranged in a circle around the center point
            // 5 circles evenly spaced around 360 degrees (72 degrees apart)
            let radius: CGFloat = 60
            
            ForEach(0..<min(colors.count, 5), id: \.self) {
                index in
                let angle = Double(index) * 72.0 * .pi / 180.0
                // 72 degrees apart in radians
                let xOffset = radius * cos(angle - .pi / 2)
                // Start from top (-π/2)
                let yOffset = radius * sin(angle - .pi / 2)
                
                colorCircle(colorIndex: index, position: .top)
                    .offset(x: xOffset, y: yOffset)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedColorIndex)
    }
    
    private func colorCircle(colorIndex: Int, position: PickerPosition) -> some View {
        let isSelected = selectedColorIndex == colorIndex
        return Circle()
            .fill(colors[colorIndex])
            .frame(width: isSelected ? 70 : 60, height: isSelected ? 70 : 60)
            .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .onTapGesture {
                hapticFeedback()
                selectedColorIndex = colorIndex
                        
                // Small delay to show selection animation, then select color
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    onColorSelected(colorIndex)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if selectedColorIndex != colorIndex {
                            selectedColorIndex = colorIndex
                            hapticFeedback()
                        }
                    }
                    .onEnded { _ in
                        onColorSelected(colorIndex)
                    }
            )
    }
    
    private func hapticFeedback() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
}

enum PickerPosition {
    case top, bottom, left, right
}

struct ColorPickerOverlay: View {
    @Binding var showingPicker: Bool
    @Binding var pickerPosition: CGPoint
    let colors: [Color]
    let onColorSelected: (Int) -> Void
    
    var body: some View { if showingPicker {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.1)
                .ignoresSafeArea()
                .onTapGesture {
                    showingPicker = false
                }
            // Color picker circles positioned around the tap point
            let radius: CGFloat = 60
            ForEach(0..<min(colors.count, 5), id: \.self) {
                index in
                let angle = Double(index) * 72.0 * .pi / 180.0
                
                // 72 degrees apart in radians
                let xOffset = radius * cos(angle - .pi / 2)
                
                // Start from top (-π/2)
                let yOffset = radius * sin(angle - .pi / 2)
                ColorCircle( color: colors[index], colorIndex: index, onColorSelected: {
                    colorIndex in
                    onColorSelected(colorIndex)
                    showingPicker = false
                }
                )
                .position( x: pickerPosition.x + xOffset, y: pickerPosition.y + yOffset )
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.8)))
        .zIndex(1000)
        
        // Ensure it appears on top
    }
    }
}

struct ColorCircle: View {
    let color: Color
    let colorIndex: Int
    let onColorSelected: (Int) -> Void
    
    @State private var isSelected = false
    
    var body: some View {
        
        Circle()
            .fill(color)
            .frame(width: isSelected ? 70 : 60, height: isSelected ? 70 : 60)
            .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .onTapGesture {
                hapticFeedback()
                isSelected = true
                // Small delay to show selection animation, then select color
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { onColorSelected(colorIndex)
                }
            }
            .gesture( DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isSelected {
                        isSelected = true
                        hapticFeedback()
                    }
                }
                .onEnded { _ in
                    onColorSelected(colorIndex)
                }
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private func hapticFeedback() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
}
