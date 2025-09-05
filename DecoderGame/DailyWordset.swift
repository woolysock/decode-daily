//
//  DailyWordset.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 8/26/25.
//
// DailyWordset.swift
import Foundation

struct DailyWordset: Codable, Identifiable, Equatable {
    let id: String      // "yyyy-MM-dd"
    let date: Date
    let words: [String]
    var isCompleted: Bool = false
    var completedAt: Date?
    
    init(date: Date, words: [String]) {
            // Use the UTC formatter directly on the input date
            self.id = Self.utcDateFormatter.string(from: date)
            self.date = date  // Keep the original date
            self.words = words
            
            print("🔆 DailyWordset init() with id: \(self.id), input date: \(date)")
        }
        
        private static let utcDateFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            f.timeZone = TimeZone(secondsFromGMT: 0)  // UTC
            f.locale = Locale(identifier: "en_US_POSIX")
            return f
        }()
    }
