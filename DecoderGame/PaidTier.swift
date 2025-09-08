//
//  PaidTier.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 9/7/25.
//


// MARK: - Subscription Manager
import Foundation

enum PaidTier: Int, CaseIterable {
    case fullAccess = 0     // Full access to all archives
    case sevenDays = 1      // Last 7 days only
    case threeDays = 2      // Last 3 days only
    case noAccess = 3       // No archive access
    
    var displayName: String {
        switch self {
        case .fullAccess: return "Premium"
        case .sevenDays: return "Standard"
        case .threeDays: return "Basic"
        case .noAccess: return "Free"
        }
    }
    
    var archiveDaysAllowed: Int {
        switch self {
        case .fullAccess: return Int.max
        case .sevenDays: return 7
        case .threeDays: return 3
        case .noAccess: return 0
        }
    }
}

class SubscriptionManager: ObservableObject {
    @Published var currentTier: PaidTier = .noAccess // Default to free tier
    
    static let shared = SubscriptionManager()
    
    private init() {
        // Load saved tier from UserDefaults
        loadCurrentTier()
    }
    
    private func loadCurrentTier() {
        let savedTier = UserDefaults.standard.integer(forKey: "userPaidTier")
        currentTier = PaidTier(rawValue: savedTier) ?? .noAccess
    }
    
    func updateTier(to newTier: PaidTier) {
        currentTier = newTier
        UserDefaults.standard.set(newTier.rawValue, forKey: "userPaidTier")
    }
    
    func canAccessArchiveDate(_ date: Date) -> Bool {
        guard currentTier != .noAccess else { return false }
        guard currentTier != .fullAccess else { return true }
        
        let today = Calendar.current.startOfDay(for: Date())
        let daysSinceDate = Calendar.current.dateComponents([.day], from: date, to: today).day ?? 0
        
        return daysSinceDate <= currentTier.archiveDaysAllowed
    }
}

// MARK: - Archive Upsell Overlay
import SwiftUI

struct ArchiveUpsellOverlay: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Main content
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.yellow)
                    
                    Text("Unlock Archive Access")
                        .font(.custom("LuloOne-Bold", size: 24))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Access past daily puzzles")
                        .font(.custom("LuloOne", size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                // Tier options
                VStack(spacing: 12) {
                    tierOptionCard(
                        tier: .fullAccess,
                        title: "Premium",
                        description: "Unlimited archive access",
                        price: "$4.99/month"
                    )
                    
                    tierOptionCard(
                        tier: .sevenDays,
                        title: "Standard",
                        description: "Last 7 days of puzzles",
                        price: "$2.99/month"
                    )
                    
                    tierOptionCard(
                        tier: .threeDays,
                        title: "Basic",
                        description: "Last 3 days of puzzles",
                        price: "$1.99/month"
                    )
                }
                
                // Close button
                Button(action: {
                    isPresented = false
                }) {
                    Text("Maybe Later")
                        .font(.custom("LuloOne", size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.top, 10)
            }
            .padding(30)
            .background(Color.myAccentColor1)
            .cornerRadius(20)
            .padding(.horizontal, 40)
        }
    }
    
    @ViewBuilder
    private func tierOptionCard(tier: PaidTier, title: String, description: String, price: String) -> some View {
        Button(action: {
            // TODO: Integrate with your payment system
            // For now, just simulate the upgrade
            subscriptionManager.updateTier(to: tier)
            isPresented = false
        }) {
            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.custom("LuloOne-Bold", size: 16))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.custom("LuloOne", size: 11))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Text(price)
                    .font(.custom("LuloOne-Bold", size: 14))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.myAccentColor2)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

