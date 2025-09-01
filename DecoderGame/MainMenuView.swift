//
//  MainMenuView.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/14/25.
//

import SwiftUI

extension Color {
//    static let myAccentColor1 = Color(red:88/255,green:93/255,blue:123/255)
//    static let myAccentColor2 = Color(red:49/255,green:52/255,blue:66/255)
    static let myAccentColor1 = Color(red:36/255,green:76/255,blue:141/255)
    //static let myAccentColor2 = Color(red:58/255,green:108/255,blue:190/255)
    static let myAccentColor2 = Color(red:98/255,green:136/255,blue:199/255)
    static let mySunColor = Color(red:246/255,green:211/255,blue:71/255)
    static let myOverlaysColor = Color(red:51/255,green:68/255,blue:97/255)
}

struct MainMenuView: View {
    
    @EnvironmentObject var scoreManager: GameScoreManager
    @EnvironmentObject var gameCoordinator: GameCoordinator
    
    let screenHeight = UIScreen.main.bounds.height
    let screenWidth = UIScreen.main.bounds.width
    var logoPadding: CGFloat = -25
    let today = Calendar.current.startOfDay(for: Date())
    
    // State for tracking button interactions with 3D tilt
    @State private var gameButtonTilts: [String: (x: Double, y: Double)] = [:]
    @State private var gameButtonPressed: [String: Bool] = [:]
    @State private var highScoreTilt: (x: Double, y: Double) = (0, 0)
    @State private var highScorePressed: Bool = false
    @State private var settingsTilt: (x: Double, y: Double) = (0, 0)
    @State private var settingsPressed: Bool = false
    @State private var navigateToGame: String? = nil
    @State private var navigateToArchivedGame: (gameId: String, date: Date)? = nil
    
    // State for page tracking
    @State private var currentPage = 0
    @State private var selectedArchiveGame: String = "flashdance"
    
    //For Archives
    @State private var selectedArchiveDate: Date?
   // @State private var navigateToArchivedGame = false
    
    // CACHE AVAILABLE DATES TO PREVENT FREQUENT CALLS
    @State private var cachedAvailableDates: [String: [Date]] = [:]
    @State private var hasLoadedInitialDates = false

    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Swipe nav bar
                HStack(alignment: .center) {
                    Spacer()
                    ForEach([0, 1, 2], id: \.self) { pageIndex in
                        Image(systemName: currentPage == pageIndex ? "smallcircle.filled.circle.fill" : "smallcircle.filled.circle")
                            .font(.system(size: currentPage == pageIndex ? 12 : 10))
                            .foregroundColor(.white)
                            .padding(.leading, pageIndex == 0 ? 30 : 0)
                            .padding(.trailing, pageIndex == 2 ? 30 : 0)
                    }
                    Spacer()
                }
                .frame(height: 60)
                .background(.black)
                
                Text(DateFormatter.day2Formatter.string(from: today))
                    .font(.custom("LuloOne-Bold", size: 14))
                    .foregroundColor(Color.myAccentColor2)
                
                Spacer()
                    .frame(height : 10)
                
                TabView(selection: $currentPage) {
                    mainMenuPage.tag(0)
                    archivesPage.tag(1)
                    accountPage.tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .navigationDestination(isPresented: Binding<Bool>(
                    get: { navigateToGame != nil },
                    set: { if !$0 { navigateToGame = nil } }
                )) {
                    if let gameId = navigateToGame {
                        destinationView(for: gameId)
                    }
                }
                .navigationDestination(isPresented: Binding<Bool>(
                    get: { navigateToArchivedGame != nil },
                    set: { if !$0 { navigateToArchivedGame = nil } }
                )) {
                    if let archivedGame = navigateToArchivedGame {
                        archivedGameDestination(for: archivedGame.gameId, date: archivedGame.date)
                    }
                }
                .onAppear {
                    loadAllAvailableDates()
                }
            }
            .background(.black)
            .ignoresSafeArea(.all, edges: .bottom) // Move this here if needed
        }
    }
    
    // MARK: - Main Menu Page
    @ViewBuilder
    private var mainMenuPage: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            GeometryReader { geo in
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height : 20)
                    
                    //game title header
                    VStack (spacing: 5){
                        Text(" DECODE!")
                            .font(.custom("LuloOne-Bold", size: 52))
                            .foregroundColor(.white)
                        Text("DAILY")
                            .font(.custom("LuloOne-Bold", size: 24))
                            .foregroundColor(.white)
                        Spacer()
                            .frame(height: 2)
                        Text("Just Puzzles. No Distractions.")
                            .font(.custom("LuloOne", size: 10))
                            .foregroundColor(.white)
                    }
                    .fixedSize()
                    .frame(width: (screenWidth))
                    
                    Spacer()
                        .frame(height: 7)
                    
                    // Dynamic game buttons from GameInfo array with tilt effect
                    ForEach(GameInfo.availableGames.filter { $0.isAvailable }, id: \.id) { gameInfo in
                        tiltableGameButton(for: gameInfo)
                    }
                    
                    Spacer()
                        .frame(height: 5)
                    
                    // High Scores button with tilt effect
                    tiltableHighScoreButton
                    
                    HStack{
                        Image(systemName: "hand.draw")
                            .font(.system(size: 20))
                            .foregroundColor(Color.myAccentColor2)
                        Text("Swipe left to view archive & settings")
                            .font(.custom("LuloOne", size: 10))
                            .foregroundColor(Color.myAccentColor2)
                            .multilineTextAlignment(.center)
                        
                    }
                    .padding(.horizontal,60)
                                        
                    Spacer()
                }
            }
        }
    }
    
    // Account Page
    @ViewBuilder
    private var accountPage: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                    .frame(height: 50)
                
                // Title for the second page
                VStack(spacing: 10) {
                    Text("Stats&\nAccount")
                        .font(.custom("LuloOne-Bold", size: 40))
                        .foregroundColor(.white)
                    
                    Text("Your gaming overview")
                        .font(.custom("LuloOne", size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                    .frame(height: 10)
                
                // Add your second page content here
                // For example, stats overview, achievements, etc.
                VStack(spacing: 20) {
                    // Total games played
                    statCard(
                        title: "Games Played",
                        value: "\(scoreManager.allScores.count)",
                        icon: "gamecontroller"
                    )
                    
                    // Best scores
                    statCard(
                        title: "Highest Score",
                        value: "\(scoreManager.getTopScores(limit: 1).first?.finalScore ?? 0)",
                        icon: "trophy"
                    )
                    
                    // Recent activity
                    statCard(
                        title: "Recent Games",
                        value: "\(scoreManager.getRecentScores(limit: 7).count)",
                        subtitle: "this week",
                        icon: "calendar"
                    )
                }
                
                Divider().background(.white).padding(5)
                
                // Settings button with tilt effect
                tiltableSettingsButton

                Spacer()
                    .frame(height: 50)
            }
            .padding(.horizontal, 40)
        }
    }
    
    // Archives Page
    @ViewBuilder
    private var archivesPage: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack() {
                
                Spacer()
                    .frame(height: 50)
                        
                
                // Title for Archives page
                VStack(alignment: .leading, spacing: 8) {
                    Text("GAME ARCHIVES")
                        .font(.custom("LuloOne-Bold", size: 40))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    Text("Blast to the past! 🚀")
                        .font(.custom("LuloOne", size: 16))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    Spacer().frame(height:1)
                    Text(" ")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                    .frame(height:25)
                
                Divider().background(.white)
                                
                // Game Selector
                HStack(spacing: 10) {
                    Button(action: {
                        selectedArchiveGame = "flashdance"
                        // Load dates for new selection if not cached
                        loadAvailableDatesIfNeeded(for: "flashdance")
                    }) {
                        Text("Flashdance")
                            .font(.custom("LuloOne-Bold", size: 12))
                            .foregroundColor(selectedArchiveGame == "flashdance" ? .black : .white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(selectedArchiveGame == "flashdance" ? Color.white : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        selectedArchiveGame = "anagrams"
                        // Load dates for new selection if not cached
                        loadAvailableDatesIfNeeded(for: "anagrams")
                    }) {
                        Text("Anagrams")
                            .font(.custom("LuloOne-Bold", size: 12))
                            .foregroundColor(selectedArchiveGame == "anagrams" ? .black : .white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(selectedArchiveGame == "anagrams" ? Color.white : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 10)
                
                //Divider().background(.white)
                
                // Date Grid - now using cached dates
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                        ForEach(getCachedAvailableDates(for: selectedArchiveGame), id: \.self) { date in
                            dateButton(for: date)
                        }
                    }
                    .padding(.horizontal, 40)
                   // .padding(.vertical, 0)
                }
                
                //Divider().background(.white.opacity(0.8))
                
            }
        }
        .onAppear {
            // Load dates for the current selection when archives page appears
            loadAvailableDatesIfNeeded(for: selectedArchiveGame)
        }
    }

    // MARK: - Date Loading Functions
    
    // Load all available dates once when the app starts
    private func loadAllAvailableDates() {
        guard !hasLoadedInitialDates else { return }
        
        print("🚀 Loading all available dates (one-time initialization)")
        
        // Load dates for all available games
        loadAvailableDatesForGame("flashdance")
        loadAvailableDatesForGame("anagrams")
        
        hasLoadedInitialDates = true
        print("✅ Finished loading all available dates")
    }
    
    // Load dates for a specific game only if not already cached
    private func loadAvailableDatesIfNeeded(for gameId: String) {
        guard cachedAvailableDates[gameId] == nil else {
            print("📋 Using cached dates for \(gameId) (\(cachedAvailableDates[gameId]?.count ?? 0) dates)")
            return
        }
        
        loadAvailableDatesForGame(gameId)
    }
    
    // Actually load the dates for a game and cache them
    private func loadAvailableDatesForGame(_ gameId: String) {
        print("🔍 Loading available dates for gameId: \(gameId)")
        let today = Calendar.current.startOfDay(for: Date())
        //print("   → Today (startOfDay): \(today)")
        print("   → Today formatted: \(DateFormatter.debugFormatter.string(from: today))")
        
        var dates: [Date] = []

        switch gameId {
        case "flashdance":
            dates = gameCoordinator.dailyEquationManager.getAvailableDates()
            print("   → Loaded \(dates.count) archive dates for flashdance")
        case "anagrams":
            dates = gameCoordinator.dailyWordsetManager.getAvailableDates()
            print("   → Loaded \(dates.count) archive dates for anagrams")
        default:
            print("   → Unknown gameId: \(gameId)")
            break
        }

        // Log the first few raw dates before processing
        //print("   → First 5 raw dates:")
        for (_, _) in dates.prefix(5).enumerated() {
            //print("     [\(index)]: \(date) -> \(DateFormatter.debugFormatter.string(from: date))")
        }

        // Convert UTC dates to local timezone dates
        let localCalendar = Calendar.current
        dates = dates.compactMap { utcDate in
            // Extract date components from the UTC date
            var utcCalendar = Calendar(identifier: .gregorian)
            utcCalendar.timeZone = TimeZone(abbreviation: "UTC")!
            
            let components = utcCalendar.dateComponents([.year, .month, .day], from: utcDate)
            
            // Create a new date using local timezone
            return localCalendar.date(from: components)
        }

        // Log the converted dates
        //print("   → First 5 converted local dates:")
        for (_, _) in dates.prefix(5).enumerated() {
            //print("     [\(index)]: \(date) -> \(DateFormatter.debugFormatter.string(from: date))")
        }

        // Filter out today and future dates, then sort
        dates = dates.filter { $0 < today }.sorted(by: >)
        
        // Log the first few filtered dates
        print("   → First 5 filtered dates (after sorting):")
        for (index, date) in dates.prefix(5).enumerated() {
            print("     [\(index)]: \(date) -> \(DateFormatter.debugFormatter.string(from: date))")
        }
        
        // Cache the results
        cachedAvailableDates[gameId] = dates
        print("   → Cached \(dates.count) dates for \(gameId)")
    }
    
    
    // Get cached dates for a game (returns empty array if not cached)
    private func getCachedAvailableDates(for gameId: String) -> [Date] {
        return cachedAvailableDates[gameId] ?? []
    }
    
    
//    // Helper function for fallback sample data
//    private func generateSampleDates(count: Int, gameId: String) -> [Date] {
//        print("   → generateSampleDates: Creating \(count) dates for \(gameId)")
//        let calendar = Calendar.current
//        let today = Date()
//        var dates: [Date] = []
//
//        // Create dates going back in time to span multiple months for color testing
//        let startDaysBack = gameId == "flashdance" ? 45 : 35 // Different starting points
//
//        for i in 0..<count {
//            if let date = calendar.date(byAdding: .day, value: -(startDaysBack + i), to: today) {
//                dates.append(date)
//            }
//        }
//
//        return dates.sorted(by: >) // Most recent first
//    }
    
    // Helper function to create date buttons
    @ViewBuilder
    private func dateButton(for date: Date) -> some View {
        
        //let _ = print("*️⃣ dateButton(\(date))")
        let calendar = Calendar.current
        let day   = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year  = calendar.component(.year, from: date)

        // Alternate colors between months
        let monthYearId = (year * 12) + month
        let backgroundColor = monthYearId % 2 == 0 ? Color.myAccentColor1 : Color.myAccentColor2

        // Show the month label only on the 1st of the month
        let showMonth = (day == 1)
        let monthAbbrev = monthAbbrevFormatter.string(from: date).uppercased()
        
        // Check if this game is completed using scoreManager
        let isCompleted = scoreManager.isGameCompleted(gameId: selectedArchiveGame, date: date)

        Button(action: {
            launchArchivedGame(gameId: selectedArchiveGame, date: date)
        }) {
            VStack(spacing: showMonth ? 2 : 0) {
                Text("\(day)")
                    .font(.custom("LuloOne-Bold", size: 16))
                    .foregroundColor(.white)

                if showMonth {
                    Text(monthAbbrev)
                        .font(.custom("LuloOne-Bold", size: 8))
                        .foregroundColor(.white.opacity(0.85))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
            }
            .frame(width: 50, height: 50)
            .background(backgroundColor)
            .cornerRadius(8)
            .overlay(
                // Checkmark overlay for completed games
                Group {
                    if isCompleted {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.yellow)
//                            .background(
//                                Circle()
//                                    .fill(Color.green)
//                                    .frame(width: 18, height: 18)
//                            )
                            .offset(x: 10, y: 10) // Position in btm-right corner
                    }
                }
            )
            .overlay(
                // White border for completed games
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isCompleted ? Color.white : Color.clear, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                Text("\(monthAbbrevFormatter.string(from: date)) \(day), \(year)\(isCompleted ? ", completed" : "")")
            )
        }
    }


    // Helper function to launch archived game
//    private func launchArchivedGame(gameId: String, date: Date) {
//        print("🏁 launchArchivedGame(): Launch \(gameId) for date: \(date)")
//        
//        // Store the selected date and game
//        selectedArchiveDate = date
//        selectedArchiveGame = gameId
//        
//        // Trigger navigation
//        navigateToArchivedGame = true
//    }
//    
    private func launchArchivedGame(gameId: String, date: Date) {
        print("🏁 launchArchivedGame(): Launch \(gameId) for date: \(date)")
        navigateToArchivedGame = (gameId: gameId, date: date)
    }
  
    
    // MARK: - Helper Views
    @ViewBuilder
    private func statCard(title: String, value: String, subtitle: String? = nil, icon: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color.myAccentColor1)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("LuloOne", size: 12))
                    .foregroundColor(.white.opacity(0.8))
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.custom("LuloOne", size: 8))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            Text(value)
                .font(.custom("LuloOne-Bold", size: 18))
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.myAccentColor2.opacity(0.2))
        .cornerRadius(10)
        .frame(maxWidth: .infinity)
    }
    
//    // Helper function to determine which game view to show
//    @ViewBuilder
//    private func gameDestination(for gameId: String) -> some View {
//        switch gameId {
//        case "decode":
//            AnyView(DecodeGameView()
//                .environmentObject(scoreManager)
//                .onAppear { gameCoordinator.setActiveGame("decode") }
//                .onDisappear { gameCoordinator.clearActiveGame() })
//        case "flashdance":
//            AnyView(FlashdanceGameView()
//                .environmentObject(scoreManager)
//                .onAppear { gameCoordinator.setActiveGame("flashdance") }
//                .onDisappear { gameCoordinator.clearActiveGame() })
//        case "anagrams":
//            AnyView(AnagramsGameView()
//                .environmentObject(scoreManager)
//                .onAppear { gameCoordinator.setActiveGame("anagrams") }
//                .onDisappear { gameCoordinator.clearActiveGame() })
//        default:
//            AnyView(EmptyView())
//        }
//    }
    
    
    // Helper function to calculate 3D tilt based on drag position
    private func calculateTilt(dragValue: DragGesture.Value, buttonWidth: CGFloat, buttonHeight: CGFloat) -> (x: Double, y: Double) {
        let maxTilt: Double = 3.0 // Much more subtle tilt in degrees
        
        // Calculate relative position from center (-1 to 1)
        let relativeX = (dragValue.location.x - (buttonWidth / 2)) / (buttonWidth / 2)
        let relativeY = (dragValue.location.y - (buttonHeight / 2)) / (buttonHeight / 2)
        
        // Convert to tilt angles
        // Y-axis rotation for left/right tilt (finger left = tilt left)
        let yTilt = min(max(relativeX * maxTilt, -maxTilt), maxTilt)
        // X-axis rotation for up/down tilt (finger up = tilt back)
        let xTilt = min(max(-relativeY * maxTilt, -maxTilt), maxTilt)
        
        return (x: xTilt, y: yTilt)
    }
    
    // Update your tiltableGameButton to use state-based navigation
    @ViewBuilder
    private func tiltableGameButton(for gameInfo: GameInfo) -> some View {
        let buttonWidth = screenWidth - 120
        let buttonHeight: CGFloat = 40 + 32
        let tilt = gameButtonTilts[gameInfo.id] ?? (0, 0)
        let isPressed = gameButtonPressed[gameInfo.id] ?? false
        
        Button(action: {
            navigateToGame = gameInfo.id  // Set the state instead of using NavigationLink
        }) {
            VStack(spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    gameInfo.gameIcon.font(.system(size: 14))
                    
                    Text(gameInfo.displayName)
                        .font(.custom("LuloOne-Bold", size: 22))
                }
                
                Text(gameInfo.description)
                    .font(.custom("LuloOne", size: 10))
            }
            .fixedSize()
            .frame(width: buttonWidth, height: 40)
            .padding()
            .background(Color.white)
            .foregroundColor(Color.black)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .rotation3DEffect(
                .degrees(tilt.x),
                axis: (x: 1, y: 0, z: 0)
            )
            .rotation3DEffect(
                .degrees(tilt.y),
                axis: (x: 0, y: 1, z: 0)
            )
            .animation(.easeOut(duration: 0.1), value: tilt.x)
            .animation(.easeOut(duration: 0.1), value: tilt.y)
            .animation(.easeOut(duration: 0.1), value: isPressed)
        }
        .disabled(!gameInfo.isAvailable)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    gameButtonPressed[gameInfo.id] = true
                    gameButtonTilts[gameInfo.id] = calculateTilt(dragValue: value, buttonWidth: buttonWidth, buttonHeight: buttonHeight)
                }
                .onEnded { _ in
                    gameButtonPressed[gameInfo.id] = false
                    withAnimation(.easeOut(duration: 0.3)) {
                        gameButtonTilts[gameInfo.id] = (0, 0)
                    }
                }
        )
    }
    
    // Add this method to your MainMenuView struct
    @ViewBuilder
    private func destinationView(for gameId: String) -> some View {
        switch gameId {
        case "decode":
            DecodeGameView()
                .environmentObject(scoreManager)
                .onAppear { gameCoordinator.setActiveGame("decode") }
                .onDisappear { gameCoordinator.clearActiveGame() }
        case "flashdance":
            FlashdanceGameView()
                .environmentObject(scoreManager)
                .onAppear { gameCoordinator.setActiveGame("flashdance") }
                .onDisappear { gameCoordinator.clearActiveGame() }
        case "anagrams":
            AnagramsGameView()
                .environmentObject(scoreManager)
                .onAppear { gameCoordinator.setActiveGame("anagrams") }
                .onDisappear { gameCoordinator.clearActiveGame() }
        case "numbers":
            NumbersGameView()
                .environmentObject(scoreManager)
                .onAppear { gameCoordinator.setActiveGame("numbers") }
                .onDisappear { gameCoordinator.clearActiveGame() }
        default:
            EmptyView()
        }
    }
    
    // Tiltable button for High Scores
    @ViewBuilder
    private var tiltableHighScoreButton: some View {
        let buttonWidth = screenWidth - 120
        let buttonHeight: CGFloat = 60 + 32 // Including padding
        
        NavigationLink(destination: MultiGameLeaderboardView()) {
            VStack(spacing: 5) {
                HStack(spacing: 10) {
                    Image(systemName: "trophy")
                        .font(.system(size: 10))
                    
                    Text("High Scores")
                        .font(.custom("LuloOne-Bold", size: 14))
                }
                Text("How did you do?")
                    .font(.custom("LuloOne", size: 10))
            }
            .padding()
            .fixedSize()
            .frame(width: buttonWidth, height: 60)
            .background(Color.myAccentColor1)
            .foregroundColor(Color.white)
            .cornerRadius(10)
            .scaleEffect(highScorePressed ? 0.98 : 1.0)
            .rotation3DEffect(
                .degrees(highScoreTilt.x),
                axis: (x: 1, y: 0, z: 0)
            )
            .rotation3DEffect(
                .degrees(highScoreTilt.y),
                axis: (x: 0, y: 1, z: 0)
            )
            .animation(.easeOut(duration: 0.1), value: highScoreTilt.x)
            .animation(.easeOut(duration: 0.1), value: highScoreTilt.y)
            .animation(.easeOut(duration: 0.1), value: highScorePressed)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    highScorePressed = true
                    highScoreTilt = calculateTilt(dragValue: value, buttonWidth: buttonWidth, buttonHeight: buttonHeight)
                }
                .onEnded { _ in
                    highScorePressed = false
                    withAnimation(.easeOut(duration: 0.3)) {
                        highScoreTilt = (0, 0)
                    }
                }
        )
    }
    
    // Tiltable button for Settings
    @ViewBuilder
    private var tiltableSettingsButton: some View {
        let buttonWidth = screenWidth - 120
        let buttonHeight: CGFloat = 60 + 32 // Including padding
        
        NavigationLink(destination: SettingsView()) {
            VStack(spacing: 5) {
                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    Image(systemName: "person.text.rectangle")
                        .font(.system(size: 10))
                    
                    Text("Settings")
                        .font(.custom("LuloOne-Bold", size: 14))
                }
                
                Text("get help, reset the app, etc.")
                    .font(.custom("LuloOne", size: 10))
            }
            .padding()
            .fixedSize()
            .frame(width: buttonWidth, height: 60)
            .background(Color.myAccentColor1)
            .foregroundColor(Color.white)
            .cornerRadius(10)
            .scaleEffect(settingsPressed ? 0.98 : 1.0)
            .rotation3DEffect(
                .degrees(settingsTilt.x),
                axis: (x: 1, y: 0, z: 0)
            )
            .rotation3DEffect(
                .degrees(settingsTilt.y),
                axis: (x: 0, y: 1, z: 0)
            )
            .animation(.easeOut(duration: 0.1), value: settingsTilt.x)
            .animation(.easeOut(duration: 0.1), value: settingsTilt.y)
            .animation(.easeOut(duration: 0.1), value: settingsPressed)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    settingsPressed = true
                    settingsTilt = calculateTilt(dragValue: value, buttonWidth: buttonWidth, buttonHeight: buttonHeight)
                }
                .onEnded { _ in
                    settingsPressed = false
                    withAnimation(.easeOut(duration: 0.3)) {
                        settingsTilt = (0, 0)
                    }
                }
        )
    }
    
    @ViewBuilder
    private func archivedGameDestination(for gameId: String, date: Date) -> some View {
        switch gameId {
        case "flashdance":
            FlashdanceGameView(targetDate: date)
                .environmentObject(scoreManager)
                .onAppear { gameCoordinator.setActiveGame("flashdance") }
                .onDisappear { gameCoordinator.clearActiveGame() }
        case "anagrams":
            AnagramsGameView(targetDate: date)
                .environmentObject(scoreManager)
                .onAppear { gameCoordinator.setActiveGame("anagrams") }
                .onDisappear { gameCoordinator.clearActiveGame() }
        default:
            EmptyView()
        }
    }
    
}

private let monthAbbrevFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX") //Locale.current
    f.setLocalizedDateFormatFromTemplate("LLL") // e.g., Jan, Feb
    return f
}()

