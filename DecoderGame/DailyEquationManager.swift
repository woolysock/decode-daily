//
//  DailyEquationManager.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue
//

import Foundation
import Combine

struct MathEquation: Codable, Identifiable {
    let expression: String    // e.g., "7 + 8"
    let answer: Int          // e.g., 15
    
    var id: String { expression }
}

struct DailyEquationSet: Codable, Identifiable {
    let id: String           // Date string "2025-01-15"
    let date: Date
    let equations: [MathEquation]
    var completedAt: Date?
}

final class DailyEquationManager: ObservableObject {
    static let shared = DailyEquationManager()
    
    @Published var currentEquationSet: DailyEquationSet?
    @Published var isGeneratingEquations: Bool = false
    @Published var generationProgress: Double = 0.0
    
    private let userDefaults = UserDefaults.standard
    private let equationSetsKey = "DailyEquationSets"
    private let dailyEquationsResource = "DailyEquations" // DailyEquations.json
    
    private var isLoadingTodaysSet = false
    private(set) var allEquationSets: [DailyEquationSet] = []
    
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    
    private init() {
        loadAllEquationSets()
        loadTodaysEquationSet()
    }
    
    func refreshForNewDay() {
        print("DailyEquationManager: Refreshing for new day")
        DispatchQueue.main.async { [weak self] in
            self?.currentEquationSet = nil
            self?.isLoadingTodaysSet = false
            self?.loadTodaysEquationSet()
        }
    }
    
    func loadTodaysEquationSet() {
        guard !isLoadingTodaysSet else { return }
        
        let today = Calendar.current.startOfDay(for: Date())
        isLoadingTodaysSet = true
        
        if let equationSet = loadEquationSet(for: today) {
            DispatchQueue.main.async { [weak self] in
                self?.currentEquationSet = equationSet
                self?.isLoadingTodaysSet = false
            }
        } else {
            generateEquationSetForDate(today)
            isLoadingTodaysSet = false
        }
    }
    
    func getTodaysEquationSet(for date: Date) -> DailyEquationSet? {
        // If requesting today's date, return the cached currentEquationSet
        let today = Calendar.current.startOfDay(for: Date())
        let requestedDate = Calendar.current.startOfDay(for: date)
        
        if Calendar.current.isDate(requestedDate, inSameDayAs: today) {
            return currentEquationSet
        }
        
        // For archive dates, load the specific equation set
        return getEquationSet(for: requestedDate)
    }
    
    // Private methods similar to DailyWordsetManager...
    private func loadAllEquationSets() {
        print("🔍 Looking for DailyEquations.json in bundle...")
        
        guard let url = Bundle.main.url(forResource: dailyEquationsResource, withExtension: "json") else {
            print("❌ DailyEquationManager - no DailyEquations.json found in bundle")
            print("📂 Available files: \(Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? [])")
            return
        }
        
        print("✅ Found DailyEquations.json at: \(url)")
        
        do {
            let data = try Data(contentsOf: url)
            //print("📊 JSON file size: \(data.count) bytes")
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(Self.dateFormatter)
            self.allEquationSets = try decoder.decode([DailyEquationSet].self, from: data)
            
            print("✅ Successfully loaded \(allEquationSets.count) equation sets")
            if let first = allEquationSets.first {
                print("📝 First set: \(first.id) with \(first.equations.count) equations")
            }
        } catch {
            print("❌ Failed to load/parse DailyEquations.json: \(error)")
        }
    }
    
    private func loadEquationSet(for date: Date) -> DailyEquationSet? {
        let dateKey = Self.dateFormatter.string(from: date)
        print("🛻 loadEquationSet(): dateKey: \(dateKey)")
        
        // Skip UserDefaults - go directly to bundled JSON
        print(" --> Searching in \(allEquationSets.count) bundled equation sets...")
        if let found = allEquationSets.first(where: { $0.id == dateKey }) {
            print(" --> ✅ Found equation set in bundled JSON for \(dateKey)")
            return found
        }

        print("❌ No equation set found for \(dateKey)")
        return nil
    }
    
    private func generateEquation(operation: Int) -> MathEquation {
        let a = Int.random(in: 1...12)
        let b = Int.random(in: 1...12)
        
        switch operation {
        case 0: // Addition
            return MathEquation(expression: "\(a) + \(b)", answer: a + b)
        case 1: // Subtraction
            let larger = max(a, b)
            let smaller = min(a, b)
            return MathEquation(expression: "\(larger) - \(smaller)", answer: larger - smaller)
        case 2: // Multiplication
            let x = Int.random(in: 2...8)
            let y = Int.random(in: 2...8)
            return MathEquation(expression: "\(x) × \(y)", answer: x * y)
        default: // Division
            let quotient = Int.random(in: 2...12)
            let divisor = Int.random(in: 2...8)
            let dividend = quotient * divisor
            return MathEquation(expression: "\(dividend) ÷ \(divisor)", answer: quotient)
        }
    }
    
    // Additional helper methods for saving/loading...
    private func generateEquationSetForDate(_ date: Date, count: Int = 20) {
        DispatchQueue.main.async { [weak self] in
            self?.isGeneratingEquations = true
            self?.generationProgress = 0.0
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let equations = self?.generateRandomEquations(count: count) ?? []
            
            DispatchQueue.main.async {
                let equationSet = DailyEquationSet(
                    id: Self.dateFormatter.string(from: date),
                    date: date,
                    equations: equations
                )
                self?.saveEquationSet(equationSet)
                self?.currentEquationSet = equationSet
                self?.isGeneratingEquations = false
                self?.generationProgress = 1.0
            }
        }
    }

    private func generateRandomEquations(count: Int) -> [MathEquation] {
        var equations: [MathEquation] = []
        
        for _ in 0..<count {
            let operation = Int.random(in: 0...3) // +, -, ×, ÷
            let equation = generateEquation(operation: operation)
            equations.append(equation)
        }
        
        return equations
    }

    private func loadEquationSetOverride(for dateKey: String) -> DailyEquationSet? {
        let key = "\(equationSetsKey)_\(dateKey)"
        guard let data = userDefaults.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(Self.dateFormatter)
        do {
            return try decoder.decode(DailyEquationSet.self, from: data)
        } catch {
            print("DailyEquationManager - failed to decode override for \(key): \(error)")
            return nil
        }
    }

    private func saveEquationSet(_ equationSet: DailyEquationSet) {
        let key = "\(equationSetsKey)_\(equationSet.id)"
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(Self.dateFormatter)
        do {
            let data = try encoder.encode(equationSet)
            userDefaults.set(data, forKey: key)
        } catch {
            print("DailyEquationManager - failed to encode equation set for \(equationSet.id): \(error)")
        }
    }
    
    func getAvailableDates() -> [Date] {
        // Map the loaded JSON sets to their actual dates
        let dates = allEquationSets.map { $0.date }
        return dates.sorted(by: >) // newest first
    }
    
    func getEquationSet(for date: Date) -> DailyEquationSet? {
        return loadEquationSet(for: date)
    }
}

