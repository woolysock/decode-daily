//
//  DailyCheckManager.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue
//

import SwiftUI
import Foundation

class DailyCheckManager: ObservableObject {
    static let shared = DailyCheckManager()
    
    @Published var showNewDayOverlay = false
    
    private let lastCheckDateKey = "lastDailyCheckDate"
    private var lastCheckDate: Date? {
        get {
            UserDefaults.standard.object(forKey: lastCheckDateKey) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: lastCheckDateKey)
        }
    }
    
    // Delegate to notify games to pause/end
    weak var gameDelegate: DailyCheckGameDelegate?
    
    private init() {
        // Start monitoring for day changes
        startDailyCheck()
    }
    
    func startDailyCheck() {
        // Check immediately on app launch
        checkForNewDay()
        
        // Set up timer to check every 10 seconds for more responsive detection
        Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.checkForNewDay()
        }
        
        // Also listen for day change notifications from system
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dayChanged),
            name: .NSCalendarDayChanged,
            object: nil
        )
        
        // Also check when app becomes active (returning from background)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func dayChanged() {
        print("System day changed notification received")
        checkForNewDay()
    }
    
    @objc private func appDidBecomeActive() {
        checkForNewDay()
    }
    
    private func checkForNewDay() {
        let today = Calendar.current.startOfDay(for: Date())
        
        // If we've never checked before, set today as the baseline
        guard let lastCheck = lastCheckDate else {
            lastCheckDate = today
            return
        }
        
        let lastCheckDay = Calendar.current.startOfDay(for: lastCheck)
        
        // If it's a different day (forward OR backward), trigger the overlay
        // This handles both normal progression and testing scenarios
        if today != lastCheckDay {
            print("Day change detected!\n ⇉ Last check: \(lastCheckDay), \n ⇉ Today: \(today)")
            
            // IMPORTANT: Refresh the wordset and equation managers for the new day
            DailyWordsetManager.shared.refreshForNewDay()
            DailyEquationManager.shared.refreshForNewDay() 
            
            // Notify games to pause/end
            gameDelegate?.newDayDetected()
            
            // Show the overlay
            DispatchQueue.main.async {
                self.showNewDayOverlay = true
            }
            
            // Update the last check date
            lastCheckDate = today
        }
    }
    
    func dismissNewDayOverlay() {
        showNewDayOverlay = false
        
        // Notify delegate that overlay was dismissed
        gameDelegate?.newDayOverlayDismissed()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// Protocol for games to implement if they need to respond to new day detection
protocol DailyCheckGameDelegate: AnyObject {
    func newDayDetected()
    func newDayOverlayDismissed()
}
