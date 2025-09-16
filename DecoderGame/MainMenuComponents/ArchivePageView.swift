//
//  ArchivePageView.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 9/15/25.
//


//
//  ArchivePageView.swift
//  Decode! Daily iOS
//
//  Created by Assistant on 9/15/25.
//

import SwiftUI

struct ArchivePageView: View {
    @Environment(\.sizeCategory) var sizeCategory
    @EnvironmentObject var scoreManager: GameScoreManager
    @EnvironmentObject var gameCoordinator: GameCoordinator
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    @Binding var selectedArchiveGame: String
    @Binding var navigateToArchivedGame: (gameId: String, date: Date)?
    @Binding var showArchiveUpsell: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
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
                        Text("Can you play them all?")
                            .font(.custom("LuloOne", size: 10))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .minimumScaleFactor(sizeCategory > .large ? 0.7 : 1.0)
                            .lineLimit(1)
                            .allowsTightening(true)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                        .frame(height: 25)
                    
                    // Game Selector
                    GameSelectorView(selectedArchiveGame: $selectedArchiveGame)
                    
                    // Date Grid
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                            ForEach(getCachedAvailableDates(for: selectedArchiveGame), id: \.self) { date in
                                ArchiveDateButtonView(
                                    date: date,
                                    gameId: selectedArchiveGame,
                                    navigateToArchivedGame: $navigateToArchivedGame,
                                    showArchiveUpsell: $showArchiveUpsell
                                )
                            }
                        }
                        .padding(.vertical, 3)
                    }
                    .padding(.horizontal, 5)
                }
                .padding(.horizontal, 30)
            }
        }
    }
    
    private func getCachedAvailableDates(for gameId: String) -> [Date] {
        return gameCoordinator.getAvailableDates(for: gameId)
    }
}
