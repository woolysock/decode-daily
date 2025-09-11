import SwiftUI

struct FancyAnimationLayer: View {
    @State private var funTextItems: [FunTextItem] = []
    @State private var isUserTouching = false
    
    // Configuration
    private let itemCount = 30
    private let baseSpeed: Double = 0.04
    private let touchSpeedMultiplier: Double = 2.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Transparent background that detects touches
                Color.clear
                    .contentShape(Rectangle())
//                    .gesture(
//                        DragGesture(minimumDistance: 0)
//                            .onChanged { _ in
//                                if !isUserTouching {
//                                    isUserTouching = true
//                                }
//                            }
//                            .onEnded { _ in
//                                isUserTouching = false
//                            }
//                    )
//                
                // Floating text items
                ForEach(funTextItems) { item in
                    FunTextView(item: item)
                        .position(item.position)
                        //.opacity(0.6)
                }
            }
        }
        .onAppear {
            setupFunTextItems()
            startAnimation()
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
                    dx: Double.random(in: -20...20),
                    dy: Double.random(in: -20...20)
                )
            )
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            updatePositions()
        }
    }
    
    private func updatePositions() {
        let screenBounds = UIScreen.main.bounds
        let currentSpeed = isUserTouching ? baseSpeed * touchSpeedMultiplier : baseSpeed
        
        for i in 0..<funTextItems.count {
            var item = funTextItems[i]
            
            // Update position
            item.position.x += item.velocity.dx * currentSpeed
            item.position.y += item.velocity.dy * currentSpeed
            
            // Bounce off edges
            if item.position.x <= 0 || item.position.x >= screenBounds.width {
                item.velocity.dx *= -1
                item.position.x = max(0, min(screenBounds.width, item.position.x))
            }
            
            if item.position.y <= 0 || item.position.y >= screenBounds.height {
                item.velocity.dy *= -1
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
    let isBold: Bool        // ← This line
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
        self.isBold = Bool.random()  // ← This sets the random value
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

//// MARK: - Usage Example for MainMenuView
//
//extension View {
//    func withFancyAnimationLayer() -> some View {
//        ZStack {
//            self
//            FancyAnimationLayer()
//                .allowsHitTesting(false)
//        }
//    }
//}
