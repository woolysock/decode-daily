//
//  StoreManager.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 9/8/25.
//


// MARK: - Product Configuration
import StoreKit
import Foundation

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
        print("🔍 Requesting products for IDs: \(ProductID.allCases.map(\.rawValue))")
        
        do {
            let storeProducts = try await Product.products(for: ProductID.allCases.map(\.rawValue))
            print("📦 Found \(storeProducts.count) products: \(storeProducts.map(\.id))")
            
            let sortedProducts = storeProducts.sorted { $0.price < $1.price }
            
            DispatchQueue.main.async {
                self.products = sortedProducts
            }
            
            print("✅ Loaded \(storeProducts.count) products")
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
        
        try? await AppStore.sync()
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
        var purchasedProductIDs: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if transaction.revocationDate == nil {
                    purchasedProductIDs.insert(transaction.productID)
                    
                }
            } catch {
                print("❌ Failed to verify transaction: \(error)")
            }
            print("🛒 UpdateCustomerProductStatus(): purchasedProductIDs: \(purchasedProductIDs)")
        }
        
        DispatchQueue.main.async {
            self.purchasedProductIDs = purchasedProductIDs
            self.updateSubscriptionManager()
        }
    }
    
    private func updateSubscriptionManager() {
        // Determine the highest tier the user has purchased
        let highestTier: PaidTier = {
            if purchasedProductIDs.contains(ProductID.premium.rawValue) {
                return .premiumAccess
            } else if purchasedProductIDs.contains(ProductID.standard.rawValue) {
                return .standardAccess
            } else {
                return .basicAccess
            }
        }()
        
        print("🔄 Updating subscription tier to: \(highestTier.displayName)")
        SubscriptionManager.shared.updateTier(to: highestTier)
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)  // Add await here
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                } catch {
                    print("❌ Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    func isPurchased(_ product: Product) -> Bool {
        return purchasedProductIDs.contains(product.id)
    }
}

enum StoreError: Error {
    case failedVerification
}

