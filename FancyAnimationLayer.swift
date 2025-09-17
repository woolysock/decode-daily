//
//  FancyAnimationLayer.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 9/10/25.
//

import SwiftUI
import CoreMotion

struct FancyAnimationLayer: View {
    @State private var funTextItems: [FunTextItem] = []
    @State private var motionManager = CMMotionManager()
    @State private var tiltForce = CGVector(dx: 0, dy: 0)
    
    // Configuration
    private let itemCount = 30
    private let baseSpeed: Double = 0.04
    private let tiltSensitivity: Double = 20.0 // Reduced for more subtle influence
    private let maxTiltForce: Double = 5.0    // Much lower max force
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Floating text items
                ForEach(funTextItems) { item in
                    FunTextView(item: item)
                        .position(item.position)
                }
            }
        }
        .onAppear {
            setupFunTextItems()
            startMotionUpdates()
            startAnimation()
        }
        .onDisappear {
            stopMotionUpdates()
        }
        .allowsHitTesting(false) // Allow touches to pass through to buttons below
    }
    
    private func setupFunTextItems() {
        let screenBounds = UIScreen.main.bounds
        
        funTextItems = (0..<itemCount).map { _ in
            FunTextItem(
                content: FunTextContent.random(),
                position: CGPoint(
                    x: Double.random(in: 0...screenBounds.width),
                    y: Double.random(in: 0...screenBounds.height)
                ),
                velocity: CGVector(
                    dx: Double.random(in: -40...40), // Increased base velocity range
                    dy: Double.random(in: -40...40)  // for more active movement
                )
            )
        }
    }
    
    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 1/60
        motionManager.startDeviceMotionUpdates(to: .main) { [self] motion, error in
            guard let motion = motion else { return }
            
            // Get device gravity vector
            let gravity = motion.gravity
            
            // Debug: Print gravity values to understand the coordinate system
            //print("Gravity - X: \(String(format: "%.3f", gravity.x)), Y: \(String(format: "%.3f", gravity.y)), Z: \(String(format: "%.3f", gravity.z))")
            
            // For portrait orientation, map gravity correctly:
            // Don't invert Y - use gravity values directly
            let forceX = gravity.x * tiltSensitivity
            let forceY = gravity.y * tiltSensitivity  // No inversion needed
            
            // Clamp the forces
            let clampedForceX = min(max(forceX, -maxTiltForce), maxTiltForce)
            let clampedForceY = min(max(forceY, -maxTiltForce), maxTiltForce)
            
            tiltForce = CGVector(dx: clampedForceX, dy: clampedForceY)
        }
    }
    
    private func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            updatePositions()
        }
    }
    
    private func updatePositions() {
        let screenBounds = UIScreen.main.bounds
        //let screenCenter = CGPoint(x: screenBounds.width / 2, y: screenBounds.height / 2)
        let screenCenter = CGPoint(x: screenBounds.width / 2, y: (screenBounds.height / 2)-100)
        
        for i in 0..<funTextItems.count {
            var item = funTextItems[i]
            
            // Calculate gentle center-seeking force
            let distanceFromCenterX = screenCenter.x - item.position.x
            let distanceFromCenterY = screenCenter.y - item.position.y
            let centerForceStrength = 0.0005 // Very gentle pull toward center
            
            // Add random variation to each item's response to tilt (comet tail effect)
            let randomVariationX = Double.random(in: -2...2)
            let randomVariationY = Double.random(in: -2...2)
            let personalTiltResponse = Double.random(in: 0.1...0.9)
            
            // Apply very gentle tilt influence (just a subtle bias)
            let appliedForceX = (tiltForce.dx + randomVariationX) * personalTiltResponse
            let appliedForceY = (tiltForce.dy + randomVariationY) * personalTiltResponse
            
            item.velocity.dx += appliedForceX * 0.02 // Tilt influence
            item.velocity.dy += appliedForceY * 0.01
            
            // Apply gentle center-seeking force
            item.velocity.dx += distanceFromCenterX * centerForceStrength
            item.velocity.dy += distanceFromCenterY * centerForceStrength
            
            // Add random movement to keep them active across the whole screen
            item.velocity.dx += Double.random(in: -1.5...1.5)
            item.velocity.dy += Double.random(in: -1.5...1.5)
            
            // Light velocity damping to maintain energy
            item.velocity.dx *= 0.995
            item.velocity.dy *= 0.995
            
            // Update position
            item.position.x += item.velocity.dx * baseSpeed
            item.position.y += item.velocity.dy * baseSpeed
            
            // Bounce off edges with good energy retention
            if item.position.x <= 0 || item.position.x >= screenBounds.width {
                item.velocity.dx *= -Double.random(in: 0.7...0.95)
                item.position.x = max(0, min(screenBounds.width, item.position.x))
            }
            
            if item.position.y <= 0 || item.position.y >= screenBounds.height {
                item.velocity.dy *= -Double.random(in: 0.7...0.95)
                item.position.y = max(0, min(screenBounds.height, item.position.y))
            }
            
            funTextItems[i] = item
        }
    }
}

// MARK: - Data Models

struct FunTextItem: Identifiable {
    let id = UUID()
    let content: FunTextContent
    let fontSize: CGFloat
    let isBold: Bool
    var position: CGPoint
    var velocity: CGVector
    
    init(content: FunTextContent, position: CGPoint, velocity: CGVector) {
        self.content = content
        self.position = position
        self.velocity = velocity
        
        // Set font properties once at creation
        switch content {
        case .letter:
            self.fontSize = CGFloat.random(in: 16...32)
        case .number:
            self.fontSize = CGFloat.random(in: 14...28)
        case .icon:
            self.fontSize = CGFloat.random(in: 18...36)
        }
        self.isBold = Bool.random()
    }
}

enum FunTextContent {
    case letter(String)
    case number(Int)
    case icon(String)
    
    static let letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "+", "-", "*", "?", "×", "÷", "="]
    static let numbers = Array(1...99)
    static let systemIcons = [
        "star.fill",
        "circle.hexagonpath",
        "xmark.triangle.circle.square",
        "bolt.fill",
        "hourglass",
        "magnifyingglass",
        "clock.badge.questionmark.fill",
        "puzzlepiece.fill",
        "lightbulb.fill",
        "crown.fill",
        "circle.fill",
        "sparkles",
        "wand.and.stars"
    ]
    
    static func random() -> FunTextContent {
        let type = Int.random(in: 0...2)
        
        switch type {
        case 0:
            return .letter(letters.randomElement()!)
        case 1:
            return .number(numbers.randomElement()!)
        default:
            return .icon(systemIcons.randomElement()!)
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .letter:
            return CGFloat.random(in: 6...46)
        case .number:
            return CGFloat.random(in: 4...76)
        case .icon:
            return CGFloat.random(in: 10...52)
        }
    }
    
    var isBold: Bool {
        return Bool.random()
    }
}

// MARK: - Views

struct FunTextView: View {
    let item: FunTextItem
    
    var body: some View {
        Group {
            switch item.content {
            case .letter(let letter):
                Text(letter)
                    .font(.custom(
                        item.isBold ? "LuloOne-Bold" : "LuloOne",
                        size: item.fontSize
                    ))
                    .foregroundColor(.myAccentColor1.opacity(0.8))
                
            case .number(let number):
                Text("\(number)")
                    .font(.custom(
                        item.isBold ? "LuloOne-Bold" : "LuloOne",
                        size: item.fontSize
                    ))
                    .foregroundColor(Color.white.opacity(0.4))
                
            case .icon(let iconName):
                Image(systemName: iconName)
                    .font(.system(
                        size: item.fontSize,
                        weight: item.isBold ? .bold : .regular
                    ))
                    .foregroundColor(Color.myAccentColor2.opacity(0.4))
            }
        }
    }
}
