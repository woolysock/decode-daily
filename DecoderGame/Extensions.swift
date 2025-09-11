//
//  Extensions.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue on 9/1/25.
//

import Foundation
import SwiftUI

extension Color {
//    static let myAccentColor1 = Color(red:88/255,green:93/255,blue:123/255)
//    static let myAccentColor2 = Color(red:49/255,green:52/255,blue:66/255)
    //static let myAccentColor2 = Color(red:98/255,green:136/255,blue:199/255)

    // Royal blue shades
//    static let myAccentColor1 = Color(red:36/255,green:76/255,blue:141/255)
//    static let myAccentColor2 = Color(red:87/255,green:152/255,blue:212/255)
    
    // Periwinkle shades
    static let myAccentColor1 = Color(red:138/255,green:155/255,blue:231/255)
    static let myAccentColor2 = Color(red:84/255,green:105/255,blue:201/255)

    
    static let mySunColor = Color(red:246/255,green:211/255,blue:71/255)
    //static let myOverlaysColor = Color(red:61/255,green:81/255,blue:116/255)
    static let myOverlaysColor = Color(red:14/255,green:30/255,blue:69/255)
    
    static let myNavy = Color(red:19/255,green:42/255,blue:98/255)
    static let myGreen = Color(red:99/255,green:249/255,blue:113/255)
    static let myCranberry = Color(red:92/255,green:0/255,blue:58/255)
    static let myPlum = Color(red:72/255,green:53/255,blue:85/255)
    static let myTeal = Color(red:0/255,green:90/255,blue:104/255)
    static let myPeriwinkle = Color(red:95/255,green:111/255,blue:187/255)
}

extension LinearGradient {
    
    static let topSwipeBarGradient = LinearGradient(
        colors: [Color.black, Color.myAccentColor1.opacity(0.7)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let bottomSwipeBarGradient = LinearGradient(
        colors: [Color.black, Color.myAccentColor2.opacity(0.1)],
        startPoint: .bottom,
        endPoint: .top
    )
    
               
    static let mainmenuViewGradient =  LinearGradient(
        colors: [Color.black, Color.myNavy.opacity(0.7)],
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )
    
    static let archivesViewGradient =  LinearGradient(
        colors: [Color.myNavy.opacity(0.1), Color.myPeriwinkle.opacity(0.8)],
        startPoint: .leading,
        endPoint: .topTrailing
    )
    
    static let statsViewGradient =  LinearGradient(
        colors: [Color.myNavy.opacity(0.1), Color.myPeriwinkle.opacity(0.8)],
        startPoint: .trailing,
        endPoint: .topLeading
    )
    
    static let highscoresNavGradient =  LinearGradient(
        colors: [Color.myAccentColor2, Color.black],
        startPoint: .top,
        endPoint: .bottom
    )
    
    
    
    
//
//    static let bottomBarGradientMainMenu = LinearGradient(
//        colors: [Color.black, Color.myNavy.opacity(0.4)],
//        startPoint: .top,
//        endPoint: .bottomLeading
//    )
//    
//    static let bottomBarGradientArchives = LinearGradient(
//        colors: [Color.black, Color.myTeal],
//        startPoint: .top,
//        endPoint: .bottomLeading
//    )
//    
//    static let bottomBarGradientStats = LinearGradient(
//        colors: [Color.black, Color.myAccentColor2.opacity(0.5)],
//        startPoint: .top,
//        endPoint: .bottomLeading
//    )
}

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
    
    static let scorePlayedDisplayFormatter: DateFormatter = {
             let formatter = DateFormatter()
     formatter.dateFormat = "MMM d, yyyy ▻ h:mm a"
     formatter.timeZone = TimeZone.current
     formatter.locale = Locale(identifier: "en_US_POSIX")
     return formatter
 }()
    
}
