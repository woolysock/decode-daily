//
//  SettingsView.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/16/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var scoreManager: GameScoreManager
    
    @State private var showingHelpOverlay = false
    @State private var showingEraseConfirmation = false
    @State private var showingEraseSuccess = false
    
    var appVersion: String {
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
            return "\(version) (\(build))"
        }
    
    var body: some View {
        ZStack {
            // Main content
            mainContent
            
            // Help overlay
            if showingHelpOverlay {
                helpOverlay
            }
        }
        .background(Color.white)
        .alert("Erase All High Scores?", isPresented: $showingEraseConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Erase All", role: .destructive) {
                scoreManager.clearAllScores()
                showingEraseSuccess = true
            }
        } message: {
            Text("This action cannot be undone. All high scores for all games will be permanently deleted.")
        }
        .alert("High Scores Deleted", isPresented: $showingEraseSuccess) {
            Button("OK") { }
        } message: {
            Text("All high scores have been successfully deleted.")
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        VStack(spacing: 0) {
            headerSection
            
            Rectangle()
                .fill(Color.white)
                .frame(height: 2)
            
            settingsContent
        }
        .background(Color.gray.opacity(0.1))
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Text("Settings")
                .font(.custom("LuloOne-Bold", size: 20))
                .foregroundColor(.black)
            
            Spacer()
            
            Button(action: {
                showingHelpOverlay = true
            }) {
                Image(systemName: "questionmark.circle")
                    .font(.title2)
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 15)
    }
    
    // MARK: - Settings Content
    private var settingsContent: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer()
                    .frame(height: 30)
                
                Text("Build:\n\(appVersion)")
                    .font(.custom("LuloOne", size: 12))
                
                eraseScoresButton
                
                // Placeholder for future settings items
            
                
                // Add some bottom padding so content doesn't stick to the bottom
                Spacer()
                    .frame(height: 50)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.gray.opacity(0.1))
    }
    
    // MARK: - Erase Scores Button
    private var eraseScoresButton: some View {
        let totalScores = scoreManager.allScores.count
        let uniqueGames = Set(scoreManager.allScores.map { $0.gameId }).count
        let hasScores = totalScores > 0
        
        return Button(action: {
            if hasScores {
                showingEraseConfirmation = true
            }
        }) {
            HStack (spacing:10){
                Image(systemName: "trash")
                    .foregroundColor(hasScores ? .red : .gray)
                    .font(.title3)
                
                if hasScores {
                    // When there are scores, use VStack layout
                    VStack(alignment: .center, spacing: 2) {
                        Text("Erase All Scores")
                            .font(.custom("LuloOne", size: 16))
                            .foregroundColor(.red)
                        
                        Text("This will erase \(totalScores) high score\(totalScores == 1 ? "" : "s") across \(uniqueGames) game\(uniqueGames == 1 ? "" : "s").")
                            .font(.custom("LuloOne", size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.red)
                        .font(.caption)
                } else {
                    // When no scores, center the text
                    Spacer()
                    
                    Text("No High Scores to Erase")
                        .font(.custom("LuloOne", size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(hasScores ? Color.red.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .disabled(!hasScores)
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
                            .foregroundColor(.gray)
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
            
            Text("For support,\nplease reach out to the team.\n\nClick to visit our website:")
                .font(.custom("LuloOne", size: 14))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
            
            Link("www.meganddesign.com", destination: URL(string: "http://www.meganddesign.com/")!)
                .font(.custom("LuloOne", size: 14))
                .foregroundColor(.blue)
        }
        .padding(30)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}
