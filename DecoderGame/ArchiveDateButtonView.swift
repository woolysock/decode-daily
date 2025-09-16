//
//  ArchiveDateButtonView.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 9/15/25.
//


//
//  ArchiveDateButtonView.swift
//  Decode! Daily iOS
//
//  Created by Assistant on 9/15/25.
//

import SwiftUI

struct ArchiveDateButtonView: View {
    @Environment(\.sizeCategory) var sizeCategory
    @EnvironmentObject var scoreManager: GameScoreManager
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    let date: Date
    let gameId: String
    @Binding var navigateToArchivedGame: (gameId: String, date: Date)?
    @Binding var showArchiveUpsell: Bool
    
    private var calendar: Calendar { Calendar.current }
    private var day: Int { calendar.component(.day, from: date) }
    private var month: Int { calendar.component(.month, from: date) }
    private var year: Int { calendar.component(.year, from: date) }
    private var monthYearId: Int { (year * 12) + month }
    private var backgroundColor: Color { 
        monthYearId % 2 == 0 ? Color.myAccentColor1 : Color.myAccentColor2 
    }
    private var monthAbbrev: String { 
        monthAbbrevFormatter.string(from: date).uppercased() 
    }
    private var isCompleted: Bool { 
        scoreManager.isGameCompleted(gameId: gameId, date: date) 
    }
    private var canAccess: Bool { 
        subscriptionManager.canAccessArchiveDate(date) 
    }
    private var badgeColor: Color { Color.myCheckmarks }
    
    var body: some View {
        Button(action: {
            if canAccess {
                launchArchivedGame()
            } else {
                showArchiveUpsell = true
            }
        }) {
            VStack(spacing: 2) {
                Text("\(day)")
                    .font(.custom("LuloOne-Bold", size: 14))
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
            .overlay(completionCheckmark)
            .overlay(lockIcon)
            .overlay(completionBorder)
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityText)
        }
    }
    
    @ViewBuilder
    private var completionCheckmark: some View {
        if isCompleted && canAccess {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(badgeColor)
                .offset(x: 10, y: 10)
                .shadow(color: .black, radius: 1)
        }
    }
    
    @ViewBuilder
    private var lockIcon: some View {
        if !canAccess {
            Image(systemName: "lock.fill")
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.9))
        }
    }
    
    @ViewBuilder
    private var completionBorder: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(isCompleted && canAccess ? Color.white : Color.clear, lineWidth: 1)
    }
    
    private var accessibilityText: Text {
        Text("\(monthAbbrevFormatter.string(from: date)) \(day), \(year)\(isCompleted ? ", completed" : "")\(canAccess ? "" : ", requires subscription")")
    }
    
    private func launchArchivedGame() {
        print("🏁 launchArchivedGame(): Launch \(gameId) for date: \(date)")
        navigateToArchivedGame = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            navigateToArchivedGame = (gameId: gameId, date: date)
        }
    }
}

private let monthAbbrevFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.setLocalizedDateFormatFromTemplate("LLL") // e.g., Jan, Feb
    return f
}()