//
//  HeaderSectionView.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 9/15/25.
//


//
//  HeaderSectionView.swift
//  Decode! Daily iOS
//
//  Created by Assistant on 9/15/25.
//

import SwiftUI

struct HeaderSectionView: View {
    @Environment(\.sizeCategory) var sizeCategory
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showArchiveUpsell = false
    
    let today = Calendar.current.startOfDay(for: Date())
    
    var body: some View {
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
        .sheet(isPresented: $showArchiveUpsell) {
            ArchiveUpsellOverlay(isPresented: $showArchiveUpsell)
                .environmentObject(subscriptionManager)
        }
    }
}