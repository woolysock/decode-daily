//
//  SettingsView.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/16/25.
//

import SwiftUI
import Mixpanel
import StoreKit

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.sizeCategory) var sizeCategory
    @EnvironmentObject var scoreManager: GameScoreManager
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    @State private var showingHelpOverlay = false
    @State private var showingEraseConfirmation = false
    @State private var showingEraseSuccess = false
    @State private var showingClearConfirmation: String? = nil
    @State private var showingClearSuccess = false
    @State private var showingRestoreSuccess = false
    @State private var showingRestoreError = false
    @State private var restoreErrorMessage = ""
    @State private var isDeveloperMode = false
    
    @StateObject private var storeManager = StoreManager.shared
    
    
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }
    
    var body: some View {
        ZStack {
            
            Color.white.ignoresSafeArea()
            
            // Main content
            mainContent
            
            // Help overlay
            if showingHelpOverlay {
                helpOverlay
            }
        }
        .background(Color.gray.opacity(0.05))
        .alert("Erase All High Scores?", isPresented: $showingEraseConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Erase All", role: .destructive) {
                scoreManager.clearAllScores()
                showingEraseSuccess = true
            }
        } message: {
            Text("This action cannot be undone. All high scores for ALL games will be permanently deleted.\n\nImportant: This will NOT reset the checkmarks tracking which games have been played. if you proceed, the scores for Decode on those dates cannot be recovered.")
        }
        .alert("High Scores Deleted", isPresented: $showingEraseSuccess) {
            Button("OK") { }
        } message: {
            Text("All high scores have been successfully deleted.")
        }
        .alert("Clear Completion Status?", isPresented: .constant(showingClearConfirmation != nil)) {
            Button("Cancel", role: .cancel) {
                showingClearConfirmation = nil
            }
            Button("Clear", role: .destructive) {
                performClearAction()
                showingClearConfirmation = nil
                showingClearSuccess = true
            }
        } message: {
            Text("This will clear completion status for \(showingClearConfirmation ?? ""). You'll be able to replay these games.")
        }
        .alert("Completion Status Cleared", isPresented: $showingClearSuccess) {
            Button("OK") { }
        } message: {
            Text("Completion status has been cleared successfully.")
        }
        .alert("Purchases Restored", isPresented: $showingRestoreSuccess) {
            Button("OK") { }
        } message: {
            Text("Your purchases have been successfully restored.")
        }
        .alert("Restore Failed", isPresented: $showingRestoreError) {
            Button("OK") { }
        } message: {
            Text(restoreErrorMessage)
        }
        .onAppear {
            // Enable developer mode for testing - you can remove this or add a tap sequence
            //isDeveloperMode = true
            
            // MIXPANEL ANALYTICS CAPTURE
            Mixpanel.mainInstance().track(event: "Settings Page View", properties: [
                "app": "Decode! Daily iOS",
                "build_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"],
                "date": Date().formatted(),
                "subscription_tier": SubscriptionManager.shared.currentTier.displayName,
                "isDeveloperMode": isDeveloperMode
            ])
            print("📈 🪵 MIXPANEL DATA LOG EVENT: Settings Page View")
            print("📈 🪵 date: \(Date().formatted())")
            print("📈 🪵 sub tier: \(SubscriptionManager.shared.currentTier.displayName)")
            print("📈 🪵 dev mode? : \(isDeveloperMode)")
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        VStack(spacing: 0) {
            headerSection
            
            Divider()
                .background(Color.myAccentColor2.opacity(0.3))
            
            settingsContent
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Text("Settings")
                .font(.custom("LuloOne-Bold", size: 20))
                .foregroundColor(.black)
                .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                .lineLimit(1)
                .allowsTightening(true)
            
            Spacer()
            
            Button(action: {
                showingHelpOverlay = true
            }) {
                Image(systemName: "questionmark.circle")
                    .font(.title2)
                    .foregroundColor(Color.myAccentColor2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 15)
        .background(Color.white)
    }
    
    // MARK: - Settings Content
    private var settingsContent: some View {
        ScrollView {
            LazyVStack(spacing: 30) {
                Spacer()
                    .frame(height: 20)
                
                // App Info Section
                settingsSection(title: "App Info") {
                    appInfoCard
                }
                .onTapGesture(count: 7) {
                    //isDeveloperMode.toggle()
                    //print("🔧 Developer mode: \(isDeveloperMode ? "ON" : "OFF")")
                }
                
                // Subscription Management Section
                settingsSection(title: "Subscription Management") {
                    VStack(spacing: 12) {
                        manageSubscriptionsCard
                        restorePurchasesCard
                    }
                }
                
                // Data Management Section
                settingsSection(title: "High Scores Data") {
                    eraseScoresCard
                }
                
                if isDeveloperMode {
                    // Developer Section (only if in developer mode)
                    settingsSection(title: "Developer Testing") {
                        
                        clearCompletionSection
                        
                        paidTierTestingCard
                        // NOTE: un/commment ^^ line to show the sub tiers for testing, if needed
                        
                        Button("Print All Scores") {
                            print("=== ALL GAME SCORES ===")
                            print("Total scores: \(scoreManager.allScores.count)")
                            for (index, score) in scoreManager.allScores.enumerated() {
                                print("[\(index)] \(score.gameId): \(score.finalScore) points on \(score.date)")
                            }
                            print("=== END SCORES ===")
                        }
                        .font(.custom("LuloOne", size: 12))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                        
                    }
                }
                
                // Legal Links Section
                VStack(spacing: 12) {
                    HStack {
                        Text("Legal Documents")
                            .font(.custom("LuloOne-Bold", size: 12))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                    
                    VStack(spacing: 8) {
                        Link(destination: URL(string: "https://www.meganddesign.com/ios-privacy-policy-decode")!) {
                            HStack {
                                Text("Privacy Policy")
                                    .font(.custom("LuloOne", size: 12))
                                    .foregroundColor(Color.myAccentColor2)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption2)
                                    .foregroundColor(Color.myAccentColor2.opacity(0.7))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.myAccentColor1.opacity(0.3), lineWidth: 0.5)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Link(destination: URL(string: "https://www.meganddesign.com/ios-terms-decode")!) {
                            HStack {
                                Text("Terms of Use")
                                    .font(.custom("LuloOne", size: 12))
                                    .foregroundColor(Color.myAccentColor2)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption2)
                                    .foregroundColor(Color.myAccentColor2.opacity(0.7))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.myAccentColor1.opacity(0.3), lineWidth: 0.5)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
                    .frame(height: 50)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.gray.opacity(0.05))
    }
    
    // MARK: - Settings Section Helper
    @ViewBuilder
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.custom("LuloOne-Bold", size: 14))
                .foregroundColor(Color.myAccentColor2)
                .padding(.horizontal, 4)
                .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                .lineLimit(1)
                .allowsTightening(true)
            
            content()
        }
    }
    
    // MARK: - App Info Card
    private var appInfoCard: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(Color.myAccentColor2)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Version")
                        .font(.custom("LuloOne-Bold", size: 14))
                        .foregroundColor(.black)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                    
                    Text(appVersion)
                        .font(.custom("LuloOne", size: 12))
                        .foregroundColor(.gray)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(1)
                        .allowsTightening(true)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.myAccentColor2.opacity(0.1), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.myAccentColor1.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Manage Subscriptions Card
    private var manageSubscriptionsCard: some View {
        Button(action: {
            openSubscriptionManagement()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "gear")
                    .foregroundColor(Color.myAccentColor2)
                    .font(.title3)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Manage Subscriptions")
                        .font(.custom("LuloOne-Bold", size: 14))
                        .foregroundColor(.black)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(2)
                        .allowsTightening(true)
                    
                    Text("Cancel or modify your subscription")
                        .font(.custom("LuloOne", size: 11))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color.myAccentColor2)
                    .font(.caption)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.myAccentColor2.opacity(0.1), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.myAccentColor1.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Restore Purchases Card
    private var restorePurchasesCard: some View {
        Button(action: {
            restorePurchases()
        }) {
            HStack(spacing: 12) {
                Image(systemName: storeManager.isLoading ? "arrow.clockwise" : "arrow.clockwise")
                    .foregroundColor(Color.myAccentColor2)
                    .font(.title3)
                    .frame(width: 24)
                    .rotationEffect(.degrees(storeManager.isLoading ? 360 : 0))
                    .animation(storeManager.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: storeManager.isLoading)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Restore Purchases")
                        .font(.custom("LuloOne-Bold", size: 14))
                        .foregroundColor(.black)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(2)
                        .allowsTightening(true)
                    
                    Text(storeManager.isLoading ? "Restoring..." : "Restore previous purchases on this device")
                        .font(.custom("LuloOne", size: 11))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if !storeManager.isLoading {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color.myAccentColor2)
                        .font(.caption)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.myAccentColor2.opacity(0.1), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.myAccentColor1.opacity(0.3), lineWidth: 1)
            )
        }
        .disabled(storeManager.isLoading)
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Erase Scores Card
    private var eraseScoresCard: some View {
        let totalScores = scoreManager.allScores.count
        let uniqueGames = Set(scoreManager.allScores.map { $0.gameId }).count
        let hasScores = totalScores > 0
        
        return Button(action: {
            if hasScores {
                showingEraseConfirmation = true
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "trash")
                    .foregroundColor(hasScores ? Color.myPlum : .gray)
                    .font(.title3)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Erase All High Scores")
                        .font(.custom("LuloOne-Bold", size: 14))
                        .foregroundColor(hasScores ? Color.myCranberry : .gray)
                        .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                        .lineLimit(4)
                        .allowsTightening(true)
                    
                    if hasScores {
                        Text("\(totalScores) score\(totalScores == 1 ? "" : "s") across \(uniqueGames) game\(uniqueGames == 1 ? "" : "s")")
                            .font(.custom("LuloOne", size: 11))
                            .foregroundColor(.gray)
                    } else {
                        Text("No scores to delete")
                            .font(.custom("LuloOne", size: 11))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                if hasScores {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color.myCranberry)
                        .font(.caption)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: hasScores ? Color.myCranberry.opacity(0.1) : Color.gray.opacity(0.05), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(hasScores ? Color.myCranberry.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .disabled(!hasScores)
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Clear Completion Section
    private var clearCompletionSection: some View {
        VStack(spacing: 8) {
            // Section header
            HStack {
                Text("Clear Game Completion")
                    .font(.custom("LuloOne-Bold", size: 12))
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Clear all button
            clearButton(
                title: "Clear All Games",
                subtitle: "Reset completion for all games",
                icon: "arrow.clockwise.circle",
                action: "all"
            )
            
            // Individual game clear buttons
            VStack(spacing: 6) {
//                clearButton(
//                    title: "Clear Decode",
//                    subtitle: "Reset Decode completion status",
//                    icon: "circle.hexagonpath",
//                    action: "decode"
//                )
//
//                clearButton(
//                    title: "Clear Flashdance",
//                    subtitle: "Reset Flashdance completion status",
//                    icon: "bolt.circle",
//                    action: "flashdance"
//                )
//
//                clearButton(
//                    title: "Clear Anagrams",
//                    subtitle: "Reset Anagrams completion status",
//                    icon: "textformat",
//                    action: "anagrams"
//                )
                
                clearButton(
                    title: "Clear Today's Games",
                    subtitle: "Reset today's completion status",
                    icon: "calendar.circle",
                    action: "today"
                )
            }
        }
    }
    
    @ViewBuilder
    private func clearButton(title: String, subtitle: String, icon: String, action: String) -> some View {
        Button(action: {
            showingClearConfirmation = action
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.custom("LuloOne-Bold", size: 12))
                        .foregroundColor(.orange)
                    
                    Text(subtitle)
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.orange)
                    .font(.caption2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.orange.opacity(0.2), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Paid Tier Testing Card
    private var paidTierTestingCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "hammer")
                    .foregroundColor(.purple)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Test Paid Tiers")
                        .font(.custom("LuloOne-Bold", size: 14))
                        .foregroundColor(.black)
                    
                    Text("Current: \(subscriptionManager.currentTier.displayName)")
                        .font(.custom("LuloOne", size: 11))
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            // Tier selection buttons
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                ForEach(PaidTier.allCases, id: \.rawValue) { tier in
                    tierTestButton(for: tier)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    @ViewBuilder
    private func tierTestButton(for tier: PaidTier) -> some View {
        Button(action: {
            subscriptionManager.updateTier(to: tier)
        }) {
            VStack(spacing: 4) {
                Text(tier.displayName)
                    .font(.custom("LuloOne-Bold", size: 11))
                    .foregroundColor(subscriptionManager.currentTier == tier ? .white : .purple)
                
                Text(tier.archiveDaysAllowed == Int.max ? "∞ days" : "\(tier.archiveDaysAllowed) days")
                    .font(.custom("LuloOne", size: 9))
                    .foregroundColor(subscriptionManager.currentTier == tier ? .white.opacity(0.8) : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(subscriptionManager.currentTier == tier ? Color.purple : Color.purple.opacity(0.1))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Functions
    private func openSubscriptionManagement() {
        Task {
            do {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                    print("Could not find window scene")
                    return
                }
                try await AppStore.showManageSubscriptions(in: windowScene)
            } catch {
                print("Failed to show subscription management: \(error)")
                // Fallback: you could show an alert here directing users to Settings > App Store > Subscriptions
            }
        }
    }
    
    private func restorePurchases() {
        Task {
            await storeManager.restorePurchases()
            
            // Check if we have any active purchases after restore
            if storeManager.purchasedProductIDs.isEmpty {
                await MainActor.run {
                    if let errorMsg = storeManager.errorMessage {
                        restoreErrorMessage = errorMsg
                        showingRestoreError = true
                    } else {
                        restoreErrorMessage = "No previous purchases found to restore."
                        showingRestoreError = true
                    }
                }
            } else {
                await MainActor.run {
                    showingRestoreSuccess = true
                }
            }
        }
    }
    
    private func performClearAction() {
        guard let action = showingClearConfirmation else { return }
        
        switch action {
        case "all":
            scoreManager.clearAllCompletionStatus()
        case "decode":
            scoreManager.clearCompletionStatus(for: "decode")
        case "flashdance":
            scoreManager.clearCompletionStatus(for: "flashdance")
        case "anagrams":
            scoreManager.clearCompletionStatus(for: "anagrams")
        case "today":
            scoreManager.clearCompletionStatus(for: Date())
        default:
            break
        }
    }
    
    // MARK: - Help Overlay
    private var helpOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    showingHelpOverlay = false
                }
            
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button(action: {
                        showingHelpOverlay = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color.myAccentColor2)
                    }
                }
                
                helpContent
            }
            .padding(40)
        }
    }
    
    // MARK: - Help Content
    private var helpContent: some View {
        VStack(spacing: 15) {
            Text("Help & Support")
                .font(.custom("LuloOne-Bold", size: 20))
                .foregroundColor(.black)
                .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                .lineLimit(2)
                .allowsTightening(true)
            
            Text("For support,\nplease reach out to the team by visiting our website")
                .font(.custom("LuloOne", size: 14))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                .allowsTightening(true)
            
            Button("☞ meganddesign.com") {
                if let url = URL(string: "https://www.meganddesign.com/decodedaily/") {
                    UIApplication.shared.open(url)
                }
            }
            .font(.custom("LuloOne", size: 16))
            .foregroundColor(Color.myAccentColor2)
            
        }
        .padding(30)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}
