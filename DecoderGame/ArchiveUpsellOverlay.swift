//
//  ArchiveUpsellOverlay.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 9/8/25.
//

// MARK: - ArchiveUpsellOverlay.swift
import SwiftUI
import StoreKit

struct ArchiveUpsellOverlay: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @StateObject private var storeManager = StoreManager.shared
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            if subscriptionManager.currentTier == .premiumAccess {
                premiumBenefitsView
            } else {
                upsellView
            }
        }
        .onAppear {
            Task {
                await storeManager.requestProducts()
            }
        }
    }
    
    // MARK: - Premium Benefits View
    @ViewBuilder
    private var premiumBenefitsView: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color.mySunColor)
                    .padding(3)
                
                Text("You've got Premium!")
                    .font(.custom("LuloOne-Bold", size: 18))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Enjoy all the benefits")
                    .font(.custom("LuloOne", size: 12))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            
            // Benefits List
            VStack(spacing: 12) {
                benefitRow(icon: "calendar.badge.checkmark", title: "Unlimited Archive Access", description: "Play any daily game from our entire collection")
                
//                benefitRow(icon: "bolt.fill", title: "Premium Support", description: "Priority customer support and early access to new features")
                
                benefitRow(icon: "sparkles", title: "Ad-Free Experience", description: "Uninterrupted gameplay without advertisements")
                
                benefitRow(icon: "gift.fill", title: "Exclusive Content", description: "Access to premium-only puzzles and challenges, coming soon!")
            }
            .padding(.vertical, 10)
            
            // Manage Subscription Button
            Button(action: {
                openSubscriptionManagement()
            }) {
                Text("Manage Subscription")
                    .font(.custom("LuloOne", size: 12))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.8), lineWidth: 1)
                    )
            }
            .padding(.top, 10)
            
            // Close button
            Button(action: {
                isPresented = false
            }) {
                Text("Continue Playing")
                
                    .font(.custom("LuloOne-Bold", size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.myAccentColor2)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding(30)
        .background(Color.myOverlaysColor)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white, lineWidth: 0.5)
        )
        .padding(.horizontal, 40)
    }
    
    @ViewBuilder
    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color.mySunColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("LuloOne-Bold", size: 12))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.custom("LuloOne", size: 10))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.myAccentColor2.opacity(0.6))
        .cornerRadius(10)
    }
    
    // MARK: - Original Upsell View
    @ViewBuilder
    private var upsellView: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "key.2.on.ring.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color.mySunColor)
                    .padding(3)
                
                Text("Unlock More Dailies")
                    .font(.custom("LuloOne-Bold", size: 14))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("from the")
                    .font(.custom("LuloOne-Bold", size: 8))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Archive")
                    .font(.custom("LuloOne-Bold", size: 30))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Dynamic free tier description
                Text("Play today's daily games plus the past \(PaidTier.basicAccess.archiveDaysAllowed) days free.\n\n★ Or Upgrade for more! ★")
                    .font(.custom("LuloOne", size: 10))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(5)
               
            }
            
            // Free tier info
            freeBasicTierCard
            
            // Loading state
            if storeManager.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                
                Text("Processing...")
                    .font(.custom("LuloOne", size: 12))
                    .foregroundColor(.white)
            }
            // Paid product options
            else if !storeManager.products.isEmpty {
                VStack(spacing: 12) {
                    ForEach(storeManager.products, id: \.id) { product in
                        productCard(for: product)
                    }
                }
            }
            // Error state
            else if let errorMessage = storeManager.errorMessage {
                VStack(spacing: 12) {
                    Text("Unable to load products")
                        .font(.custom("LuloOne-Bold", size: 16))
                        .foregroundColor(.red)
                    
                    Text(errorMessage)
                        .font(.custom("LuloOne", size: 12))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Button("Retry") {
                        Task {
                            await storeManager.requestProducts()
                        }
                    }
                    .font(.custom("LuloOne", size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            }
            
            // Restore purchases button
            if !storeManager.products.isEmpty {
                Button("Restore Purchases") {
                    Task {
                        await storeManager.restorePurchases()
                    }
                }
                .font(.custom("LuloOne", size: 10))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 10)
            }
            
            // Close button
            Button(action: {
                isPresented = false
            }) {
                Text("Maybe Later")
                    .font(.custom("LuloOne", size: 12))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.8), lineWidth: 1)
                    )
            }
            .padding(.top, 10)
        }
        .padding(30)
        .background(Color.myOverlaysColor)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white, lineWidth: 0.5)
        )
        .padding(.horizontal, 40)
    }
    
    @ViewBuilder
    private var freeBasicTierCard: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Basic")
                    .font(.custom("LuloOne-Bold", size: 14))
                    .foregroundColor(.white)
                
                if subscriptionManager.currentTier == .basicAccess {
                    Text("Current Plan")
                        .font(.custom("LuloOne-Bold", size: 10))
                        .foregroundColor(Color.mySunColor)
                }
                // Dynamic description for basic tier
                Text("Last \(PaidTier.basicAccess.archiveDaysAllowed) days of games")
                    .font(.custom("LuloOne", size: 11))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Text("FREE")
                .font(.custom("LuloOne-Bold", size: 14))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(subscriptionManager.currentTier == .basicAccess ? Color.myAccentColor2.opacity(0.7) : Color.myAccentColor2.opacity(0.4))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func productCard(for product: Product) -> some View {
        let isPurchased = storeManager.isPurchased(product)
        let productTier = ProductID(rawValue: product.id)?.tier
        let description = tierDescription(for: productTier)
        
        Button(action: {
            if !isPurchased {
                Task {
                    await storeManager.purchase(product)
                    if storeManager.isPurchased(product) {
                        isPresented = false
                    }
                }
            }
        }) {
            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(product.displayName)
                        .font(.custom("LuloOne-Bold", size: 14))
                        .foregroundColor(.white)
             
                    if subscriptionManager.currentTier == productTier {
                        Text("Current Plan")
                            .font(.custom("LuloOne-Bold", size: 10))
                            .foregroundColor(Color.mySunColor)
                    }
                    Text(description)
                        .font(.custom("LuloOne", size: 11))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 3) {
                    if isPurchased {
                        Text("✔︎")
                            .font(.custom("LuloOne-Bold", size: 26))
                            .foregroundColor(.green)
                    } else {
                        Text(product.displayPrice)
                            .font(.custom("LuloOne-Bold", size: 14))
                            .foregroundColor(.white)
                        Text("/yr")
                            .font(.custom("LuloOne", size: 6))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.myAccentColor2)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isPurchased || storeManager.isLoading)
    }
    
    private func tierDescription(for tier: PaidTier?) -> String {
        guard let tier = tier else { return "Unknown tier" }
        
        switch tier {
        case .premiumAccess:
            return "Unlimited\nplay!"
        case .standardAccess:
            return "Last \(tier.archiveDaysAllowed) days of games"
        case .basicAccess:
            return "Last \(tier.archiveDaysAllowed) days of games"
        }
    }
    
    // MARK: - Subscription Management
    
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
}
