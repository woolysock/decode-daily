//
//  SubscriptionTierBadge.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 9/9/25.
//

import SwiftUI

// Subscription tier badge component that works with your PaidTier enum
struct SubscriptionTierBadge: View {
    let tier: PaidTier
    
    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 6) {
            // Tier icon/symbol
            tierIcon
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(tierTextColor)
            
            // Tier name
            Text(tierDisplayName)
                .font(.custom("LuloOne-Bold", size: 11))
                .foregroundColor(tierTextColor)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .background(tierBackgroundView)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(tierBorderColor, lineWidth: 1.5)
        )
        .cornerRadius(12)
        .shadow(color: tierShadowColor, radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Tier-specific styling
    
    private var tierIcon: Image {
        switch tier {
        case .basicAccess:
            return Image(systemName: "lock.fill")//"lock.trianglebadge.exclamationmark.fill")
        case .standardAccess:
            return Image(systemName: "checkmark.seal.fill")//"lock.badge.clock.fill")
        case .premiumAccess:
            return Image(systemName: "crown.fill")
        }
    }
    
    private var tierDisplayName: String {
        return tier.displayName.uppercased()
    }
    
    private var tierBackgroundView: some View {
        switch tier {
        case .basicAccess:
            return AnyView(Color.myAccentColor2.opacity(0.2))
        case .standardAccess:
            return AnyView(
                LinearGradient(
                    colors: [Color.myAccentColor1, Color.myAccentColor2],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        case .premiumAccess:
            return AnyView(
                LinearGradient(
                    colors: [Color.purple.opacity(0.8), Color.myAccentColor1],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
    }
    
    private var tierTextColor: Color {
        switch tier {
        case .basicAccess:
            return .white.opacity(0.9)
        case .standardAccess:
            return .white
        case .premiumAccess:
            return .white
        }
    }
    
    private var tierBorderColor: Color {
        switch tier {
        case .basicAccess:
            return .white.opacity(0.3)
        case .standardAccess:
            return .white.opacity(0.6)
        case .premiumAccess:
            return .white.opacity(0.6)
        }
    }
    
    private var tierShadowColor: Color {
        switch tier {
        case .basicAccess:
            return .clear
        case .standardAccess:
            return Color.myAccentColor2.opacity(0.3)
        case .premiumAccess:
            return .purple.opacity(0.3)
        }
    }
}

// Alternative seal-style badge
struct SubscriptionTierSeal: View {
    let tier: PaidTier
    
    var body: some View {
        ZStack {
            // Background seal shape
            Circle()
                .fill(sealBackgroundView)
                .frame(width: 35, height: 35)
            
            // Border/rim effect
            Circle()
                .stroke(sealBorderColor, lineWidth: 2)
                .frame(width: 35, height: 35)
            
            // Inner icon
            sealIcon
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(sealIconColor)
        }
        .shadow(color: sealShadowColor, radius: 3, x: 0, y: 2)
    }
    
    private var sealIcon: Image {
        switch tier {
        case .basicAccess:
            return Image(systemName: "lock.fill")
        case .standardAccess:
            return Image(systemName: "hourglass")
        case .premiumAccess:
            return Image(systemName: "lock.open.fill")
        }
    }
    
    private var sealBackgroundView: some ShapeStyle {
        switch tier {
        case .basicAccess:
            return AnyShapeStyle(Color.gray.opacity(0.6))
        case .standardAccess:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.mySunColor, Color.mySunColor.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
        case .premiumAccess:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.purple, Color.blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
    
    private var sealBorderColor: Color {
        switch tier {
        case .basicAccess:
            return .white.opacity(0.5)
        case .standardAccess:
            return .orange
        case .premiumAccess:
            return .white
        }
    }
    
    private var sealIconColor: Color {
        switch tier {
        case .basicAccess:
            return .white
        case .standardAccess:
            return .black
        case .premiumAccess:
            return .white
        }
    }
    
    private var sealShadowColor: Color {
        switch tier {
        case .basicAccess:
            return .clear
        case .standardAccess:
            return Color.mySunColor.opacity(0.4)
        case .premiumAccess:
            return .purple.opacity(0.4)
        }
    }
}
