//
//  MainMenuView.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/14/25.
//

import SwiftUI
import Mixpanel

struct MainMenuView: View {
    //for screen size responsiveness
    @Environment(\.sizeCategory) var sizeCategory
    
    @EnvironmentObject var scoreManager: GameScoreManager
    @EnvironmentObject var gameCoordinator: GameCoordinator
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showArchiveUpsell = false
    
    let screenHeight = UIScreen.main.bounds.height
    let screenWidth = UIScreen.main.bounds.width
    let today = Calendar.current.startOfDay(for: Date())
    
    // State for tracking button interactions with 3D tilt
    @State private var gameButtonTilts: [String: (x: Double, y: Double)] = [:]
    @State private var gameButtonPressed: [String: Bool] = [:]
    @State private var highScoreTilt: (x: Double, y: Double) = (0, 0)
    @State private var highScorePressed: Bool = false
    @State private var settingsTilt: (x: Double, y: Double) = (0, 0)
    @State private var settingsPressed: Bool = false
    @State private var navigateToGame: String? = nil
    
    // State for page tracking
    @State private var currentPage: Int
    @State private var hasUserSwiped: Bool = UserDefaults.standard.bool(forKey: "hasSeenSwipeInstruction")
    
    //For Archives
    @State private var selectedArchiveDate: Date?
    @State private var selectedArchiveGame: String = "decode"
    @State private var navigateToArchivedGame: (gameId: String, date: Date)? = nil
    
    init(initialPage: Int = 0, selectedGame: String = "decode") {
        _currentPage = State(initialValue: initialPage)
        _selectedArchiveGame = State(initialValue: selectedGame)
        
        // Print all UserDefaults keys and values
        //        print("=== GAME USER DEFAULTS ===")
        //        let userDefaults = UserDefaults.standard
        //        let allKeys = userDefaults.dictionaryRepresentation()
        //
        //        // Filter for keys that might be related to your game
        //        let gameKeys = allKeys.filter { key, _ in
        //            key.contains("game") ||
        //            key.contains("score") ||
        //            key.contains("completion") ||
        //            key.contains("userPaidTier") ||
        //            key.contains("hasSeenSwipeInstruction") ||
        //            key.contains("decode") ||
        //            key.contains("flashdance") ||
        //            key.contains("anagrams")
        //        }
        //
        //        for (key, value) in gameKeys.sorted(by: { $0.key < $1.key }) {
        //            print("\(key): \(value)")
        //        }
        //        print("=== END GAME USER DEFAULTS ===")
        
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer().frame(height: 5)
                    headerSection
                    mainTabView
                    bottomNavigationBar
                    Spacer().frame(height: 20)
                }
                .zIndex(0)
                .background(.clear)
                .ignoresSafeArea(.all, edges: .bottom)
                
                if showArchiveUpsell {
                    ArchiveUpsellOverlay(isPresented: $showArchiveUpsell)
                        .environmentObject(subscriptionManager)
                        .zIndex(1)
                }
            }
            .navigationBarBackButtonHidden(true)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToArchive"))) { notification in
            handleArchiveNavigation(notification)
        }
        .environmentObject(subscriptionManager)
    }
    
    private var headerSection: some View {
        HStack {
            Text(DateFormatter.day2Formatter.string(from: today))
                .font(.custom("LuloOne-Bold", size: 12))
                .foregroundColor(Color.myAccentColor1)
                .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                .lineLimit(1)
                .allowsTightening(true)
                .padding(20)
            
            Spacer()
            
            Button(action: {
                showArchiveUpsell = true
                //let _ = print("🛒 SubTierBadge: currentTier: \(subscriptionManager.currentTier)")
            }) {
                SubscriptionTierBadge(tier: subscriptionManager.currentTier)
            }
        }
        .padding(.bottom, sizeCategory > .medium ? 8 : 12)
        .padding(.horizontal, sizeCategory > .medium ? 20 : 50)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(.white.opacity(0.8)),
            alignment: .bottom
        )
    }
    
    private var mainTabView: some View {
        TabView(selection: $currentPage) {
            mainMenuPage.tag(0)
            archivesPage.tag(1)
            accountPage.tag(2)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .navigationDestination(isPresented: gameNavigationBinding) {
            if let gameId = navigateToGame {
                destinationView(for: gameId)
            }
        }
        .navigationDestination(isPresented: archivedGameNavigationBinding) {
            if let archivedGame = navigateToArchivedGame {
                archivedGameDestination(for: archivedGame.gameId, date: archivedGame.date)
            }
        }
        .onAppear {
            //loadAllAvailableDates()
        }
        .onChange(of: currentPage) {
            handlePageChange()
        }
    }
    
    private var gameNavigationBinding: Binding<Bool> {
        Binding<Bool>(
            get: { navigateToGame != nil },
            set: { if !$0 { navigateToGame = nil } }
        )
    }
    
    private var archivedGameNavigationBinding: Binding<Bool> {
        Binding<Bool>(
            get: { navigateToArchivedGame != nil },
            set: { if !$0 { navigateToArchivedGame = nil } }
        )
    }
    
    private var bottomNavigationBar: some View {
        HStack(alignment: .center) {
            Spacer()
            ForEach([0, 1, 2], id: \.self) { pageIndex in
                pageIndicator(for: pageIndex)
            }
            Spacer()
        }
        .frame(height: 55)
        .background(LinearGradient.bottomSwipeBarGradient)
    }
    
    private func pageIndicator(for pageIndex: Int) -> some View {
        Image(systemName: currentPage == pageIndex ? "smallcircle.filled.circle.fill" : "smallcircle.filled.circle")
            .font(.system(size: currentPage == pageIndex ? 14 : 12))
            .foregroundColor(.white)
            .padding(.leading, pageIndex == 0 ? 30 : 0)
            .padding(.trailing, pageIndex == 2 ? 30 : 0)
    }
    
    private func handlePageChange() {
        if currentPage != 0 && !hasUserSwiped {
            hasUserSwiped = true
            UserDefaults.standard.set(true, forKey: "hasSeenSwipeInstruction")
        }
    }
    
    private func handleArchiveNavigation(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let gameId = userInfo["gameId"] as? String {
            currentPage = 1
            selectedArchiveGame = gameId
        }
    }
    
    // MARK: - Main Menu Page
    @ViewBuilder
    private var mainMenuPage: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient.mainmenuViewGradient.ignoresSafeArea()
                FancyAnimationLayer()
                
                
                ScrollView(.vertical) {
                    VStack(spacing: sizeCategory > .medium ? 15 : 20) {
                        
                        Spacer()
                            .frame(height: sizeCategory > .medium ? 30 : 60)
                        
                        //game title header
                        VStack (spacing: 5){
                            Text(" DECODE!")
                                .font(.custom("LuloOne-Bold", size: sizeCategory > .medium ? 46 : 52))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(sizeCategory > .medium ? 0.7 : 1.0)
                                .allowsTightening(true)
                            Text("DAILY")
                                .font(.custom("LuloOne-Bold", size: 24))
                                .foregroundColor(.white)
                                .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                .lineLimit(1)
                                .allowsTightening(true)
                            Spacer()
                                .frame(height: 3)
                            // Text("Just Puzzles. No Distractions.")
                            
                            
                            Text("fun games, clean & simple\n＋ new challenges every day!\nsizeCategory: \(sizeCategory)\nscreen wxh: \(screenWidth), \(screenHeight)")
                                .font(.custom("LuloOne", size: 10))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                .allowsTightening(true)
                        }
                        
                        Spacer()
                            .frame(height: 6)
                        
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
                            Text("Swipe to view archive & settings")
                                .font(.custom("LuloOne", size: 9))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                .lineLimit(1)
                                .allowsTightening(true)
                        }
                        .padding(.horizontal,50)
                        .opacity(hasUserSwiped ? 0 : 1)
                        .animation(.easeOut(duration: 0.5), value: hasUserSwiped)
                        
                        Spacer()
                    }
                }
                .frame(alignment: .center)
            }
            .onChange(of: currentPage) { oldValue, newValue in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if currentPage == newValue {
                        switch newValue {
                        case 0:
                            // MIXPANEL ANALYTICS CAPTURE: Main Menu Page View
                            Mixpanel.mainInstance().track(event: "Main Menu Page View", properties: [
                                "app": "Decode! Daily iOS",
                                "build_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"],
                                "date": Date().formatted(),
                                "subscription_tier": SubscriptionManager.shared.currentTier.displayName
                            ])
                            print("📈 🪵 MIXPANEL DATA LOG EVENT: Main Menu Page View (oC)")
                            print("📈 🪵 date: \(Date().formatted())")
                            print("📈 🪵 sub tier: \(SubscriptionManager.shared.currentTier.displayName)")
                        case 1:
                            print("📈 🪵 case 1: will capture an archive view")
                            // MIXPANEL ANALYTICS CAPTURE: Archives Main Page View
                            Mixpanel.mainInstance().track(event: "Archives Main Page View", properties: [
                                "app": "Decode! Daily iOS",
                                "build_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"],
                                "date": Date().formatted(),
                                "subscription_tier": SubscriptionManager.shared.currentTier.displayName
                            ])
                            print("📈 🪵 MIXPANEL DATA LOG EVENT: Archives Main Page View")
                            print("📈 🪵 date: \(Date().formatted())")
                            print("📈 🪵 sub tier: \(SubscriptionManager.shared.currentTier.displayName)")
                        case 2:
                            // MIXPANEL ANALYTICS CAPTURE: Stats Main Page View
                            Mixpanel.mainInstance().track(event: "Stats Main Page View", properties: [
                                "app": "Decode! Daily iOS",
                                "build_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"],
                                "date": Date().formatted(),
                                "subscription_tier": SubscriptionManager.shared.currentTier.displayName
                            ])
                            print("📈 🪵 MIXPANEL DATA LOG EVENT: Stats Main Page View")
                            print("📈 🪵 date: \(Date().formatted())")
                            print("📈 🪵 sub tier: \(SubscriptionManager.shared.currentTier.displayName)")
                        default:
                            break
                        }
                    }
                }
            }
            .onAppear{
                //print("DEBUG onAppear for Main Menu.... currentPage: \(currentPage)")
                if currentPage == 0 {
                    // MIXPANEL ANALYTICS CAPTURE for Main Menu Page View
                    Mixpanel.mainInstance().track(event: "Main Menu Page View:", properties: [
                        "app": "Decode! Daily iOS",
                        "build_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"],
                        "date": Date().formatted(),
                        "subscription_tier": SubscriptionManager.shared.currentTier.displayName
                    ])
                    print("📈 🪵 MIXPANEL DATA LOG EVENT: Main Menu Page View (oA)")
                    print("📈 🪵 date: \(Date().formatted())")
                    print("📈 🪵 sub tier: \(SubscriptionManager.shared.currentTier.displayName)")
                }
            }
        }
    }
    
    
    // Account Page
    @ViewBuilder
    private var accountPage: some View {
        ScrollView {
            ZStack {
                //Color.black.ignoresSafeArea()
                LinearGradient.statsViewGradient.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: sizeCategory > .large ? 20 : 30)
                    
                    // Title for the second page
                    VStack(spacing: 10) {
                        Text("Stats &\nAccount")
                            .font(.custom("LuloOne-Bold", size: 40))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                            .allowsTightening(true)
                        
                        // Stats go here
                        VStack(spacing: sizeCategory > .large ? 14 : 18) {
                            // Total games played
                            statCard(
                                title: "Games Played",
                                value: "\(scoreManager.allScores.count)",
                                icon: "gamecontroller"
                            )
                            
                            // Recent activity
                            statCard(
                                title: "Recent Games",
                                value:  "\(scoreManager.getScoresFromLastWeek().count)",
                                subtitle: "this week",
                                icon: "calendar"
                            )
                            
                            Spacer()
                                .frame(height:sizeCategory > .large ? 1 : 5)
                            
                            Text("High Scores")
                                .font(.custom("LuloOne", size: 12))
                                .foregroundColor(.white.opacity(0.8))
                                .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                                .lineLimit(1)
                                .allowsTightening(true)
                            
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
                            .padding(.horizontal, sizeCategory > .medium ? 10 : 20)
                        }
                        .padding(.horizontal, sizeCategory > .medium ? 20 : 40)
                    }
                    
                    Divider().background(.white)
                    
                    // Settings button with tilt effect
                    tiltableSettingsButton
                    
                    Spacer()
                    
                }
                .padding(.horizontal, sizeCategory > .medium ? 30 : 40)
            }
        }
    }
    
    // Archives Page
    @ViewBuilder
    private var archivesPage: some View {
        ZStack {
            //Color.black.ignoresSafeArea()
            LinearGradient.archivesViewGradient.ignoresSafeArea()
            
            VStack() {
                
                Spacer()
                    .frame(height: sizeCategory > .large ? 40 : 50)
                
                // Title for Archives page
                VStack(alignment: .leading, spacing: 8) {
                    Text("DAILY ARCHIVE")
                        .font(.custom("LuloOne-Bold", size: 40))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(2)
                        .allowsTightening(true)
                    Text("Blast to the past! 🚀")
                        .font(.custom("LuloOne", size: 16))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                    //Spacer().frame(height:1)
                    Text("Can you play them all?")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                    .frame(height:25)
                
                //Divider().background(.white)
                
                // Game Selector
                HStack(spacing: 10) {
                    Button(action: {
                        selectedArchiveGame = "decode"
                        // Load dates for new selection if not cached
                        // loadAvailableDatesIfNeeded(for: "decode")
                    }) {
                        Text("Decode")
                            .font(.custom("LuloOne-Bold", size: 11))
                            .foregroundColor(selectedArchiveGame == "decode" ? .black : .white)
                            .padding(.horizontal, sizeCategory > .medium ? 15 : 18)
                            .padding(.vertical, sizeCategory > .medium ? 10 : 15)
                            .background(selectedArchiveGame == "decode" ? Color.white : Color.clear)
                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                            .lineLimit(2)
                            .allowsTightening(true)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        selectedArchiveGame = "flashdance"
                        // Load dates for new selection if not cached
                        //  loadAvailableDatesIfNeeded(for: "flashdance")
                    }) {
                        Text("Flash\ndance")
                            .font(.custom("LuloOne-Bold", size: 11))
                            .foregroundColor(selectedArchiveGame == "flashdance" ? .black : .white)
                            .padding(.horizontal, sizeCategory > .medium ? 15 : 18)
                            .padding(.vertical, sizeCategory > .medium ? 8 : 10)
                            .background(selectedArchiveGame == "flashdance" ? Color.white : Color.clear)
                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                            .lineLimit(2)
                            .allowsTightening(true)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        selectedArchiveGame = "anagrams"
                        // Load dates for new selection if not cached
                        //  loadAvailableDatesIfNeeded(for: "anagrams")
                    }) {
                        Text("'Grams")
                            .font(.custom("LuloOne-Bold", size: 11))
                            .foregroundColor(selectedArchiveGame == "anagrams" ? .black : .white)
                            .padding(.horizontal, sizeCategory > .medium ? 15 : 18)
                            .padding(.vertical, sizeCategory > .medium ? 10 : 15)
                            .background(selectedArchiveGame == "anagrams" ? Color.white : Color.clear)
                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                            .lineLimit(2)
                            .allowsTightening(true)
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
                
                // Date Grid
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                        ForEach(getCachedAvailableDates(for: selectedArchiveGame), id: \.self) { date in
                            dateButton(for: date)
                        }
                    }
                    .padding(.horizontal, sizeCategory > .medium ? 20 : 40)
                    .padding(.vertical, 3)
                }
                
            }
        }
    }
    
    
    // Helper function to create date buttons
    @ViewBuilder
    private func dateButton(for date: Date) -> some View {
        let calendar = Calendar.current
        let day   = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year  = calendar.component(.year, from: date)
        
        // Alternate colors between months
        let monthYearId = (year * 12) + month
        let backgroundColor = monthYearId % 2 == 0 ? Color.myAccentColor1 : Color.myAccentColor2
        
        // Show the month label only on the 1st of the month
        //let showMonth = (day == 1)
        let monthAbbrev = monthAbbrevFormatter.string(from: date).uppercased()
        
        // Check if this game is completed using scoreManager
        let isCompleted = scoreManager.isGameCompleted(gameId: selectedArchiveGame, date: date)
        
        // Check if this date is accessible based on subscription tier
        let canAccess = subscriptionManager.canAccessArchiveDate(date)
        
        let badgeColor = Color.myCheckmarks
        
        Button(action: {
            if canAccess {
                //let _ = print("🔓 UNLOCKED: Date tapped: \(date), canAccess: \(canAccess), tier: \(subscriptionManager.currentTier)")
                
                launchArchivedGame(gameId: selectedArchiveGame, date: date)
            } else {
                // Show upsell overlay
                //let _ = print("🔒 LOCKED: Date tapped: \(date), canAccess: \(canAccess), tier: \(subscriptionManager.currentTier)")
                showArchiveUpsell = true
            }
        }) {
            VStack(spacing: 2) {
                Text("\(day)")
                    .font(.custom("LuloOne-Bold", size: 14)) //sizeCategory > .large ? 14 : 16))
                    .foregroundColor(canAccess ? .white : .white.opacity(0.4))
                    .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                    .lineLimit(1)
                    .allowsTightening(true)
                    .multilineTextAlignment(.center)
                
                if canAccess {
                    Text(monthAbbrev)
                        .font(.custom("LuloOne-Bold", size: sizeCategory > .large ? 7 : 10))
                        .foregroundColor(canAccess ? .white.opacity(0.85) : .white.opacity(0.3))
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(width: 50, height: 50)
            .background(canAccess ? backgroundColor : backgroundColor.opacity(0.4))
            .cornerRadius(8)
            .overlay(
                // Checkmark overlay for completed games (only if accessible)
                Group {
                    if isCompleted && canAccess {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(badgeColor)
                            .offset(x: 10, y: 10)
                            .shadow(color: .black, radius: 1)
                    }
                }
            )
            .overlay(
                // Lock icon for inaccessible dates
                Group {
                    if !canAccess {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            )
            .overlay(
                // White border for completed games (only if accessible)
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isCompleted && canAccess ? Color.white : Color.clear, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                Text("\(monthAbbrevFormatter.string(from: date)) \(day), \(year)\(isCompleted ? ", completed" : "")\(canAccess ? "" : ", requires subscription")")
            )
        }
    }
    
    private func launchArchivedGame(gameId: String, date: Date) {
        print("🏁 launchArchivedGame(): Launch \(gameId) for date: \(date)")
        navigateToArchivedGame = nil
        // Set new navigation after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            navigateToArchivedGame = (gameId: gameId, date: date)
        }
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
                    .foregroundColor(.white)
                    .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                    .lineLimit(2)
                    .allowsTightening(true)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.custom("LuloOne", size: 8))
                        .foregroundColor(.white.opacity(0.8))
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                }
            }
            
            Spacer()
            
            Text(value)
                .font(.custom("LuloOne-Bold", size: 18))
                .foregroundColor(.white)
                .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                .lineLimit(1)
                .allowsTightening(true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        //.background(Color.myOverlaysColor.opacity(0.8))
        .background(.clear)
        .cornerRadius(10)
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func gameStatCard(gameId: String, gameName: String, icon: String) -> some View {
        let gameScores = scoreManager.getScores(for: gameId)
        let highestScore = gameScores.first  // Add this line
        let highScore = highestScore?.finalScore ?? 0  // Update this line
        let gamesPlayed = gameScores.count
        
        NavigationLink(destination: MultiGameLeaderboardView(selectedGameID: gameId)) {
            
            HStack(spacing: 15) {
                
                //Game Name & Count Played on left
                VStack(alignment: .leading, spacing: 3) {
                    Text(gameName)
                        .font(.custom("LuloOne-Bold", size: 12))
                        .foregroundColor(.white)
                        .minimumScaleFactor(sizeCategory > .medium ? 0.7 : 1.0)
                        .lineLimit(2)
                        .allowsTightening(true)
                    
                    if gamesPlayed > 0 {
                        Text("\(gamesPlayed) game\(gamesPlayed == 1 ? "" : "s")")
                            .font(.custom("LuloOne", size: 10))
                            .foregroundColor(.white.opacity(0.8))
                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                            .lineLimit(1)
                            .allowsTightening(true)
                    } else {
                        Text("Not played")
                            .font(.custom("LuloOne", size: 10))
                            .foregroundColor(.white.opacity(0.8))
                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                            .lineLimit(1)
                            .allowsTightening(true)
                    }
                }
                
                Spacer()
                
                // Highest score & date achieved
                VStack(alignment: .trailing, spacing: 2) {
                    Text(gamesPlayed > 0 ? "\(highScore)" : "—")
                        .font(.custom("LuloOne-Bold", size: 16))
                        .foregroundColor(gamesPlayed > 0 ? .white : .white.opacity(0.4))
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                    
                    if gamesPlayed > 0, let score = highestScore {
                        Text(DateFormatter.day2Formatter.string(from: score.date))
                            .font(.custom("LuloOne", size: 10))
                            .foregroundColor(.white.opacity(0.8))
                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                            .lineLimit(1)
                            .allowsTightening(true)
                    } else {
                        Text("Not played")
                            .font(.custom("LuloOne", size: 10))
                            .foregroundColor(.white.opacity(0.8))
                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                            .lineLimit(1)
                            .allowsTightening(true)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(Color.myAccentColor2)
            .cornerRadius(10)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle()) // Prevents default button styling
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
        let buttonHeight = screenHeight / 8
        let tilt = gameButtonTilts[gameInfo.id] ?? (0, 0)
        let isPressed = gameButtonPressed[gameInfo.id] ?? false
        let checkDate =  Calendar.current.startOfDay(for: Date())
        let isCompleted = scoreManager.isGameCompleted(gameId: gameInfo.id, date: checkDate)
        
        Button(action: {
            navigateToGame = gameInfo.id  // Set the state instead of using NavigationLink
        }) {
            HStack(alignment: .center) {
                
                Spacer()
                    .frame(width: 1)
                
                gameInfo.gameIcon.font(.system(size: 26))
                    .frame(maxWidth: buttonHeight)
                
                Spacer()
                    .frame(width: 5)
                
                VStack(alignment: .leading, spacing: 5) {
                    
                    Text(gameInfo.displayName)
                        .font(.custom("LuloOne-Bold", size: 20))
                        .minimumScaleFactor(sizeCategory > .medium ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                    
                    Text(gameInfo.description)
                        .font(.custom("LuloOne", size: 10))
                        .minimumScaleFactor(sizeCategory > .medium ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                        .multilineTextAlignment(.leading)
                    
                    Text("buttonHeight:\(buttonHeight)")
                        .font(.custom("LuloOne", size: 6))
                        .minimumScaleFactor(sizeCategory > .medium ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            }
            .frame(width: buttonWidth, height: buttonHeight)
            .frame(alignment: .leading)
            .padding(sizeCategory > .medium ? 5 : 10)
            .background(Color.mainMenuGameButtonBg)//(Color.white)
            .foregroundColor(Color.mainMenuGameButtonFg)
            .overlay(
                Rectangle().stroke(Color.mainMenuGameButtonSt, lineWidth: 0.5)
            )
            .shadow(color: .black, radius: 3)
            .scaleEffect(isPressed ? 0.97 : 1.0)
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
                        .foregroundColor(Color.myCheckmarks)
                        .offset(x: (buttonWidth/2)-2, y: (-buttonHeight/2)+5) // Position in btm-right corner
                }
            }
        )
        
        
    }
    
    // Add this helper method to your MainMenuView class
    private func getMostRecentlyPlayedGame() -> String? {
        //print("🔍 DEBUG: Getting most recently played game...")
        //print("   - Total scores count: \(scoreManager.allScores.count)")
        
        // Print all scores with dates for debugging
        let sortedScores = scoreManager.allScores.sorted { $0.date > $1.date }
        //print("   - All scores (most recent first):")
        //        for (index, score) in sortedScores.prefix(5).enumerated() {
        //            print("     [\(index)]: \(score.gameId) - \(score.date) - Score: \(score.finalScore)")
        //        }
        
        let recentScore = sortedScores.first
        let gameId = recentScore?.gameId ?? "decode"
        
        //print("   - Most recent score: \(String(describing: recentScore))")
        // print("   - Returning game ID: '\(gameId)'")
        
        return gameId
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
        
        // Determine the most recently played game
        let mostRecentGameId = getMostRecentlyPlayedGame()
        
        NavigationLink(destination: MultiGameLeaderboardView(selectedGameID: mostRecentGameId)) {
            VStack(spacing: 5) {
                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    Image(systemName: "trophy")
                        .font(.system(size: 10))
                    
                    Text("High Scores")
                        .font(.custom("LuloOne-Bold", size: 14))
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                }
                Text("How did you do?")
                    .font(.custom("LuloOne", size: 10))
                    .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                    .lineLimit(1)
                    .allowsTightening(true)
            }
            .padding()
            .fixedSize()
            .frame(width: buttonWidth, height: 60)
            .background(Color.myAccentColor1.opacity(0.9))
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
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                }
                
                Text("get help, reset the app, etc.")
                    .font(.custom("LuloOne", size: sizeCategory > .large ? 8 : 10))
                    .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                    .lineLimit(1)
                    .allowsTightening(true)
            }
            .padding(10)
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
        //let _ = print("📍 archivedGameDestination(): \(gameId) - \(date)")
        
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
                .id("decode-\(date.timeIntervalSince1970)") // ← Add this line
                .onAppear { gameCoordinator.setActiveGame("decode") }
                .onDisappear { gameCoordinator.clearActiveGame() }
        default:
            let _ = print("🔍 TRACE: Unknown gameId in archivedGameDestination: \(gameId)")
            EmptyView()
        }
    }
    
    private func getCachedAvailableDates(for gameId: String) -> [Date] {
        return gameCoordinator.getAvailableDates(for: gameId)
    }
    
}

private let monthAbbrevFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX") //Locale.current
    f.setLocalizedDateFormatFromTemplate("LLL") // e.g., Jan, Feb
    return f
}()

