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
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.id = formatter.string(from: date)
        self.date = date
        self.words = words
    }
}
