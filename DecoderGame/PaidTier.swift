//
//  PaidTier.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 9/7/25.
//

// MARK: - PaidTier.swift
import Foundation

enum PaidTier: Int, CaseIterable {
    case premiumAccess = 0     // Full access to all archives - PAID
    case standardAccess = 1      // Last 7 days only - PAID
    case basicAccess = 2      // No archive access - FREE (fallback)
    
    
    var displayName: String {
        switch self {
        case .premiumAccess: return "Premium"
        case .standardAccess: return "Standard"
        case .basicAccess: return "Free"
        }
    }
    
    var archiveDaysAllowed: Int {
        switch self {
        case .premiumAccess: return Int.max
        case .standardAccess: return 7
        case .basicAccess: return 3
        }
    }
    
    var isPaid: Bool {
        switch self {
        case .premiumAccess, .standardAccess: return true
        case .basicAccess: return false
        }
    }
    
    enum ProductID: String, CaseIterable {
        case premium = "com.decodedaily.premium"
        case standard = "com.decodedaily.standard"
        case basic = "com.decodedaily.basic"
        
        var tier: PaidTier {
            switch self {
            case .premium: return .premiumAccess
            case .standard: return .standardAccess
            case .basic: return .basicAccess
            }
        }
    }
}

class SubscriptionManager: ObservableObject {
    @Published var currentTier: PaidTier = .basicAccess // Default to FREE basic tier
    
    static let shared = SubscriptionManager()
    
    private init() {
        loadCurrentTier()
    }
    
    private func loadCurrentTier() {
        let savedTier = UserDefaults.standard.integer(forKey: "userPaidTier")
        print ("⏳ ...loadCurrentTier(): savedTier: \(savedTier)")
        currentTier = PaidTier(rawValue: savedTier) ?? .basicAccess // Default to FREE basic tier
        print ("⏳ ...loadCurrentTier(): currentTier: \(currentTier)")
    }
    
    func updateTier(to newTier: PaidTier) {
        currentTier = newTier
        UserDefaults.standard.set(newTier.rawValue, forKey: "userPaidTier")
    }
    
    func canAccessArchiveDate(_ date: Date) -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let daysSinceDate = Calendar.current.dateComponents([.day], from: date, to: today).day ?? 0
        
        return daysSinceDate <= currentTier.archiveDaysAllowed
    }
}
