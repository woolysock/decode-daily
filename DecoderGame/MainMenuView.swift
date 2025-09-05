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
    static let myAccentColor2 = Color(red:87/255,green:152/255,blue:212/255)
    //static let myAccentColor2 = Color(red:98/255,green:136/255,blue:199/255)
    
    static let mySunColor = Color(red:246/255,green:211/255,blue:71/255)
    static let myOverlaysColor = Color(red:61/255,green:81/255,blue:116/255)
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
    @State private var selectedArchiveGame: String = "decode"
    
    @State private var hasUserSwiped: Bool = false
    
    //For Archives
    @State private var selectedArchiveDate: Date?
   // @State private var navigateToArchivedGame = false
    
    // CACHE AVAILABLE DATES TO PREVENT FREQUENT CALLS
    @State private var cachedAvailableDates: [String: [Date]] = [:]
    @State private var hasLoadedInitialDates = false

    
    var body: some View {
            NavigationStack {
            VStack(spacing: 0) {
                
                // Top swipe nav bar (just dates - dots at bottom)
                Spacer().frame(height: 25)
                Text(DateFormatter.day2Formatter.string(from: today))
                    .font(.custom("LuloOne-Bold", size: 14))
                    .foregroundColor(Color.myAccentColor2)
                    .padding(20)
                    //.background(.yellow)
                //Spacer().frame(height : 10)
                
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
                    //let _ = print("🔍 TRACE: navigationDestination called")
                    //let _ = print("   Stack trace: \(Thread.callStackSymbols.prefix(5).joined(separator: "\n   "))")
                        
                    if let archivedGame = navigateToArchivedGame {
                        archivedGameDestination(for: archivedGame.gameId, date: archivedGame.date)
                    }
                }
                .onAppear {
                    loadAllAvailableDates()
                }
                .onChange(of: currentPage) {
                    // Hide the swipe instruction once user has swiped away from main page
                    if currentPage != 0 && !hasUserSwiped {
                        hasUserSwiped = true
                    }
                }
                
                // Bottom swipe nav bar
                HStack(alignment: .center) {
                    Spacer()
                    ForEach([0, 1, 2], id: \.self) { pageIndex in
                        Image(systemName: currentPage == pageIndex ? "smallcircle.filled.circle.fill" : "smallcircle.filled.circle")
                            .font(.system(size: currentPage == pageIndex ? 14 : 12))
                            .foregroundColor(.white)
                            .padding(.leading, pageIndex == 0 ? 30 : 0)
                            .padding(.trailing, pageIndex == 2 ? 30 : 0)
                    }
                    Spacer()
                }
                .frame(height: 55)
                .background(.black)
                Spacer().frame(height:20)
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
                    
                    Spacer()
                        .frame(height: 1)
                                        
                    HStack{
                        Image(systemName: "hand.draw")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        Text("Swipe left to view archive & settings")
                            .font(.custom("LuloOne", size: 9))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal,50)
                    .opacity(hasUserSwiped ? 0 : 1)
                    .animation(.easeOut(duration: 0.5), value: hasUserSwiped)
                                        
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
                    .frame(height: 20)
                
                // Title for the second page
                VStack(spacing: 10) {
                    Text("Stats &\nAccount")
                        .font(.custom("LuloOne-Bold", size: 40))
                        .foregroundColor(.white)
                        .lineLimit(2, reservesSpace: true)
                    
                    Text("Your gaming overview")
                        .font(.custom("LuloOne", size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
                
//                Spacer()
//                    .frame(height: 10)
                
                // Stats go here
                VStack(spacing: 18) {
                    // Total games played
                    statCard(
                        title: "Games Played",
                        value: "\(scoreManager.allScores.count)",
                        icon: "gamecontroller"
                    )
                    
                    // Recent activity
                    statCard(
                        title: "Recent Games",
                        value: "\(scoreManager.getRecentScores(limit: 7).count)",
                        subtitle: "this week",
                        icon: "calendar"
                    )
                    
                    Text("High Scores")
                        .font(.custom("LuloOne", size: 12))
                        .foregroundColor(.white.opacity(0.8))
                    
                    // Game-specific high scores
                    VStack(spacing: 10) {
                        // Decode high score
                        gameStatCard(
                            gameId: "decode",
                            gameName: "Decode",
                            icon: "circle.hexagonpath"
                        )
                        
                        // Flashdance high score
                        gameStatCard(
                            gameId: "flashdance",
                            gameName: "Flashdance",
                            icon: "bolt.circle"
                        )
                        
                        // Anagrams high score
                        gameStatCard(
                            gameId: "anagrams",
                            gameName: "'Grams",
                            icon: "60.arrow.trianglehead.clockwise"
                        )
                    }
                    .padding(.horizontal, 20)
                    
                }
                
                Divider().background(.white)
                
                // Settings button with tilt effect
                tiltableSettingsButton

                Spacer()

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
                    .frame(height: 40)
                        
                // Title for Archives page
                VStack(alignment: .leading, spacing: 8) {
                    Text("DAILY ARCHIVES")
                        .font(.custom("LuloOne-Bold", size: 40))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    Text("Blast to the past! 🚀")
                        .font(.custom("LuloOne", size: 16))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    //Spacer().frame(height:1)
                    Text("● Tap the buttons to switch games.\n● Scroll to view past dates.")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                    .frame(height:15)
                
                Divider().background(.white)
                                
                // Game Selector
                HStack(spacing: 10) {
                    Button(action: {
                        selectedArchiveGame = "decode"
                        // Load dates for new selection if not cached
                        loadAvailableDatesIfNeeded(for: "decode")
                    }) {
                        Text("Decode")
                            .font(.custom("LuloOne-Bold", size: 12))
                            .foregroundColor(selectedArchiveGame == "decode" ? .black : .white)
                            .padding(.horizontal, 25)
                            .padding(.vertical, 15)
                            .background(selectedArchiveGame == "decode" ? Color.white : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        selectedArchiveGame = "flashdance"
                        // Load dates for new selection if not cached
                        loadAvailableDatesIfNeeded(for: "flashdance")
                    }) {
                        Text("Flash\ndance")
                            .font(.custom("LuloOne-Bold", size: 12))
                            .foregroundColor(selectedArchiveGame == "flashdance" ? .black : .white)
                            .padding(.horizontal, 25)
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
                        Text("'Grams")
                            .font(.custom("LuloOne-Bold", size: 12))
                            .foregroundColor(selectedArchiveGame == "anagrams" ? .black : .white)
                            .padding(.horizontal, 25)
                            .padding(.vertical, 15)
                            .background(selectedArchiveGame == "anagrams" ? Color.white : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                            .cornerRadius(8)
                    }
                }
                //.padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 10)
                
                //Divider().background(.white)
                
                // Date Grid - now using cached dates
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                        ForEach(getCachedAvailableDates(for: selectedArchiveGame), id: \.self) { date in
                            dateButton(for: date)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 3)
                }
                
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
        
        print("... 🗘 MainMenuView: loadAllAvailableDates(): Loading all dates for all games (one-time initialization):")
        
        // Load dates for all available games
        loadAvailableDatesForGame("decode")
        loadAvailableDatesForGame("flashdance")
        loadAvailableDatesForGame("anagrams")
        
        
        hasLoadedInitialDates = true
        print("✅ Finished loading, sorting & filtering all available dates.")
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
        //print("🔍 Loading available dates for gameId: \(gameId)")
        let today = Calendar.current.startOfDay(for: Date())
        print("   → Today (startOfDay): \(today)")
        print("   → Today formatted: \(DateFormatter.debugFormatter.string(from: today))")
        
        var dates: [Date] = []

        switch gameId {
        case "decode":
            dates = gameCoordinator.dailyCodeSetManager.getAvailableDates()
            print("   → Loaded \(dates.count) archive dates for decode")
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
//        print("   → First 3 raw dates:")
//        for (_, _) in dates.prefix(1).enumerated() {
//            print("     [\(index)]: \(dates)") // -> \(dates.isoDayString)")
//        }

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
        //for (_, _) in dates.prefix(5).enumerated() {
            //print("     [\(index)]: \(date) -> \(DateFormatter.debugFormatter.string(from: date))")
        //}

        // Filter out today and future dates, then sort
        dates = dates.filter { $0 < today }.sorted(by: >)
        
        // Log the first few filtered dates
        print("   →   → Date Sample after sorting, filtering:")
        for (index, date) in dates.prefix(1).enumerated() {
            print("     [\(index)]: \(date) -> \(date.isoDayString)")
        }
        
        // Cache the results
        cachedAvailableDates[gameId] = dates
        print("   → Cached \(dates.count) dates for \(gameId)")
    }
    
    
    // Get cached dates for a game (returns empty array if not cached)
    private func getCachedAvailableDates(for gameId: String) -> [Date] {
        return cachedAvailableDates[gameId] ?? []
    }
    
    
    
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
                .foregroundColor(Color.myAccentColor2)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("LuloOne", size: 12))
                    .foregroundColor(.white)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.custom("LuloOne", size: 8))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Spacer()
            
            Text(value)
                .font(.custom("LuloOne-Bold", size: 18))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 11)
        .background(Color.myOverlaysColor.opacity(0.8))
        .cornerRadius(10)
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func gameStatCard(gameId: String, gameName: String, icon: String) -> some View {
        let gameScores = scoreManager.getScores(for: gameId)
        let highestScore = gameScores.first  // Add this line
        let highScore = highestScore?.finalScore ?? 0  // Update this line
        let gamesPlayed = gameScores.count
        
        HStack(spacing: 15) {
            
            //Game Name & Count Played on left
            VStack(alignment: .leading, spacing: 3) {
                Text(gameName)
                    .font(.custom("LuloOne-Bold", size: 12))
                    .foregroundColor(.white)
                
                if gamesPlayed > 0 {
                    Text("\(gamesPlayed) game\(gamesPlayed == 1 ? "" : "s")")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    Text("Not played")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Spacer()
            
            // Highest score & date achieved
            VStack(alignment: .trailing, spacing: 2) {
                Text(gamesPlayed > 0 ? "\(highScore)" : "—")
                    .font(.custom("LuloOne-Bold", size: 18))
                    .foregroundColor(gamesPlayed > 0 ? .white : .white.opacity(0.4))
                
                if gamesPlayed > 0, let score = highestScore {
                    Text(DateFormatter.day2Formatter.string(from: score.date))
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    Text("Not played")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(Color.myAccentColor2)
        .cornerRadius(10)
        .frame(maxWidth: .infinity)
    }
    
    
    // Helper function to calculate 3D tilt based on drag position
    private func calculateTilt(dragValue: DragGesture.Value, buttonWidth: CGFloat, buttonHeight: CGFloat) -> (x: Double, y: Double) {
        let maxTilt: Double = 3.0
        
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
    
    // Update tiltableGameButton to use state-based navigation
    @ViewBuilder
    private func tiltableGameButton(for gameInfo: GameInfo) -> some View {
        let buttonWidth = screenWidth - 120
        let buttonHeight: CGFloat = 40 + 32
        let tilt = gameButtonTilts[gameInfo.id] ?? (0, 0)
        let isPressed = gameButtonPressed[gameInfo.id] ?? false
        let checkDate =  Calendar.current.startOfDay(for: Date())
        let isCompleted = scoreManager.isGameCompleted(gameId: gameInfo.id, date: checkDate)
        
        // Debug the completion check
        if gameInfo.id == "flashdance" {
            let _ = print("🔍 Button checking completion for \(gameInfo.id) at \(checkDate)")
            
            let _ = scoreManager.debugGameCompletion(gameId: gameInfo.id, date: checkDate)
        }
        
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
        .overlay(
            // Checkmark overlay for completed games
            Group {
                if isCompleted {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.yellow)
                    .offset(x: (buttonWidth/2)-3, y: 15) // Position in btm-right corner
                }
            }
        )
       
    }
    
    
    @ViewBuilder
    private func destinationView(for gameId: String) -> some View {
        //let _ = print("🔍 TRACE: destinationView called with gameId: \(gameId)")
        //let _ =  print("   Stack trace: \(Thread.callStackSymbols.prefix(5).joined(separator: "\n   "))")
            
        
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
                    
                    Text("Top Scores")
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
        case "decode":
            DecodeGameView(targetDate: date)
                .environmentObject(scoreManager)
                .onAppear { gameCoordinator.setActiveGame("decode") }
                .onDisappear { gameCoordinator.clearActiveGame() }
        default:
            let _ = print("🔍 TRACE: Unknown gameId in archivedGameDestination: \(gameId)")
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

