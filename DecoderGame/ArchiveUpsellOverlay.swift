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
            
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.yellow)
                    
                    Text("Unlock More Dailies")
                        .font(.custom("LuloOne-Bold", size: 18))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("from the")
                        .font(.custom("LuloOne-Bold", size: 10))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Archive")
                        .font(.custom("LuloOne-Bold", size: 28))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Always play the\nlast 3 days free.\nUpgrade for more!")
                        .font(.custom("LuloOne", size: 10))
                        .foregroundColor(.white.opacity(0.8))
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
        .onAppear {
            Task {
                await storeManager.requestProducts()
            }
        }
    }
    
    @ViewBuilder
    private var freeBasicTierCard: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Basic")
                    .font(.custom("LuloOne-Bold", size: 14))
                    .foregroundColor(.white)
                
                if subscriptionManager.currentTier == .basicAccess {
                    Text("Current")
                        .font(.custom("LuloOne-Bold", size: 10))
                        .foregroundColor(Color.mySunColor)
                }
                Text("Last 3 days of games")
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
        .background(Color.myAccentColor2.opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.5), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func productCard(for product: Product) -> some View {
        let isPurchased = storeManager.isPurchased(product)
        let productTier = ProductID(rawValue: product.id)?.tier
        let description = tierDescription(for: productTier)
        
        //let _ = print("productCard")
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
             
                    if productTier == .basicAccess {
                        Text("Current")
                            .font(.custom("LuloOne-Bold", size: 10))
                            .foregroundColor(Color.mySunColor)
                    }
                    Text(description)
                        .font(.custom("LuloOne", size: 11))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                if isPurchased {
                    Text("✔︎")
                        .font(.custom("LuloOne-Bold", size: 16))
                        .foregroundColor(.green)
                } else {
                    Text(product.displayPrice)
                        .font(.custom("LuloOne-Bold", size: 14))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isPurchased ? Color.myAccentColor2.opacity(0.5) : Color.myAccentColor2)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isPurchased || storeManager.isLoading)
    }
    
    private func tierDescription(for tier: PaidTier?) -> String {
        switch tier {
        case .premiumAccess: return "Unlimited play"
        case .standardAccess: return "Last 7 days of games"
        case .basicAccess, .none: return "Last 7 days of games"
        }
    }
}
