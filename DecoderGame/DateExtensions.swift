//
//  DateExtensions.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 9/1/25.
//

import Foundation

extension Date {
    
    /// Returns the start of the day in the current calendar & timezone
    var localStartOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    /// Returns a formatted string for display (e.g., "Sep 1, 2025")
    func formattedForDisplay() -> String {
        let formatter = DateFormatter.dayFormatter
        return formatter.string(from: self)
    }
    
       /// ISO yyyy-MM-dd string for keys
       var isoDayString: String {
           let formatter = DateFormatter()
           formatter.dateFormat = "yyyy-MM-dd"
           formatter.timeZone = TimeZone.current
           formatter.locale = Locale(identifier: "en_US_POSIX")
           return formatter.string(from: self)
       }
    
}

extension DateFormatter {
    
    /// Shared formatter for displaying dates consistently
       static let dayFormatter: DateFormatter = {
                let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    static let day2Formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM dd, yyyy"
        f.timeZone = TimeZone.current // or fixed timezone if needed
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    
    static let debugFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss z"
        f.timeZone = TimeZone.current
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    
    static let dayStringFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // Always UTC
        formatter.locale = Locale.current
        return formatter
    }()
    
}
