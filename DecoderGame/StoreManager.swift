//
//  StoreManager.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 9/8/25.
//

// MARK: - Product Configuration
import StoreKit
import Foundation
import Mixpanel

// Only define PAID tiers - Basic is free
enum ProductID: String, CaseIterable {
    case premium = "com.decodedaily.premium"     // Full access
    case standard = "com.decodedaily.standard"
    case basic = "com.decodedaily.basic" // 3 days for free? should we hide this?
    
    var tier: PaidTier {
        switch self {
        case .premium: return .premiumAccess
        case .standard: return .standardAccess
        case .basic: return .basicAccess // should we hide this?
        }
    }
}

struct SubscriptionEntitlement {
    let productID: String
    let purchaseDate: Date
    let willRenew: Bool
}

@MainActor
class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    static let shared = StoreManager()
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        updateListenerTask = listenForTransactions()
        
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func requestProducts() async {
        //print("🔍 Requesting products for IDs: \(ProductID.allCases.map(\.rawValue))")
        
        do {
            let storeProducts = try await Product.products(for: ProductID.allCases.map(\.rawValue))
            let sortedProducts = storeProducts.sorted { $0.price < $1.price }
            
            DispatchQueue.main.async {
                self.products = sortedProducts
            }
            
            print("✅ Loaded Product Options: \(storeProducts.count) products")
        } catch {
            print("❌ Failed to load products: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load products: \(error.localizedDescription)"
            }
        }
    }
    
    func purchase(_ product: Product) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateCustomerProductStatus()
                await transaction.finish()
                
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                print("✅ Purchase successful: \(product.id)")
                
            case .userCancelled:
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                print("🚫 User cancelled purchase")
                
            case .pending:
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Purchase is pending approval"
                }
                print("⏳ Purchase pending")
                
            @unknown default:
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Unknown purchase result"
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Purchase failed: \(error.localizedDescription)"
            }
            print("❌ Purchase failed: \(error)")
        }
    }
    
    func restorePurchases() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        // Just check current entitlements - no sync needed to avoid hanging
        await updateCustomerProductStatus()
        
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    func updateCustomerProductStatus() async {
        var activeEntitlements: [SubscriptionEntitlement] = []
        
        // Get current active entitlements WITH their purchase dates and renewal status
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if transaction.revocationDate == nil {
                    // Check if subscription will renew
                    let willRenew: Bool
                    let daysUntilExpiration: Int
                    
                    if let expiration = transaction.expirationDate {
                        daysUntilExpiration = Calendar.current.dateComponents([.day], from: Date(), to: expiration).day ?? 0
                        // Wait until expiration approach (industry standard)
                        // Most apps let users keep premium until billing period ends
                        willRenew = daysUntilExpiration > 1
                    } else {
                        daysUntilExpiration = Int.max
                        willRenew = true
                    }
                    
                    activeEntitlements.append(SubscriptionEntitlement(
                        productID: transaction.productID,
                        purchaseDate: transaction.purchaseDate,
                        willRenew: willRenew
                    ))
                    
                    print("📋 Active entitlement: \(transaction.productID)")
                    print("   Purchase: \(transaction.purchaseDate)")
                    print("   Will renew: \(willRenew)")
                    if daysUntilExpiration != Int.max {
                        print("   Days until expiration: \(daysUntilExpiration)")
                    }
                }
            } catch {
                print("❌ Failed to verify transaction: \(error)")
            }
        }
        
        // Determine effective subscription
        let effectiveSubscription: String?
        
        if activeEntitlements.isEmpty {
            effectiveSubscription = nil
            print("🛒 No active subscriptions found")
        } else if activeEntitlements.count == 1 {
            effectiveSubscription = activeEntitlements.first?.productID
            print("🛒 Single active subscription: \(effectiveSubscription ?? "none")")
        } else {
            // Multiple subscriptions - use most recent purchase
            let mostRecent = activeEntitlements.max { $0.purchaseDate < $1.purchaseDate }
            effectiveSubscription = mostRecent?.productID
            
            print("🛒 Multiple active subscriptions detected:")
            for entitlement in activeEntitlements.sorted(by: { $0.purchaseDate > $1.purchaseDate }) {
                let status = entitlement.willRenew ? "active" : "expiring soon"
                print("   - \(entitlement.productID): \(entitlement.purchaseDate) (\(status))")
            }
            print("🎯 Using most recent: \(effectiveSubscription ?? "none")")
        }
        
        let purchasedProductIDs: Set<String>
        if let subscription = effectiveSubscription {
            purchasedProductIDs = [subscription]
        } else {
            purchasedProductIDs = []
        }
        
        print("🛒 UpdateCustomerProductStatus(): effectivePurchasedIDs: \(purchasedProductIDs)")
        
        DispatchQueue.main.async {
            self.purchasedProductIDs = purchasedProductIDs
            self.updateSubscriptionManager()
        }
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    print("🔔 New transaction detected: \(transaction.productID)")
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                } catch {
                    print("❌ Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    private func updateSubscriptionManager() {
        let oldTier = SubscriptionManager.shared.currentTier
        
        // Your existing tier determination logic...
        let newTier: PaidTier = {
            if purchasedProductIDs.contains(ProductID.premium.rawValue) {
                return .premiumAccess
            } else if purchasedProductIDs.contains(ProductID.standard.rawValue) {
                return .standardAccess
            } else {
                return .basicAccess
            }
        }()
        
        // Track subscription change if tier actually changed
        if oldTier != newTier {
            // MIXPANEL ANALYTICS CAPTURE
            Mixpanel.mainInstance().track(event: "User Subscription Changed", properties: [
                "app": "Decode! Daily iOS",
                "build_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"],
                "previous_tier": oldTier.displayName,
                "new_tier": newTier.displayName,
                "change_type": determineChangeType(from: oldTier, to: newTier),
                "date": Date().formatted()
            ])
            print("📈 🪵 MIXPANEL DATA LOG EVENT: User Subscription Changed")
            print("📈 🪵 date: \(Date().formatted())")
            print("📈 🪵 old tier: \(oldTier.displayName)")
            print("📈 🪵 new tier: \(newTier.displayName)")
        }
        
        SubscriptionManager.shared.updateTier(to: newTier)
    }

    private func determineChangeType(from oldTier: PaidTier, to newTier: PaidTier) -> String {
        if newTier.rawValue < oldTier.rawValue { return "upgrade" }
        else if newTier.rawValue > oldTier.rawValue { return "downgrade" }
        else { return "no_change" }
    }
    
    func isPurchased(_ product: Product) -> Bool {
        return purchasedProductIDs.contains(product.id)
    }
}

enum StoreError: Error {
    case failedVerification
}
