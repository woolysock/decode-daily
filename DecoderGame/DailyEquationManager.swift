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
    var isCompleted: Bool = false
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
    
    func getTodaysEquationSet() -> DailyEquationSet? {
        return currentEquationSet
    }
    
    // Private methods similar to DailyWordsetManager...
    private func loadAllEquationSets() {
        guard let url = Bundle.main.url(forResource: dailyEquationsResource, withExtension: "json") else {
            print("DailyEquationManager - no DailyEquations.json found")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(Self.dateFormatter)
            self.allEquationSets = try decoder.decode([DailyEquationSet].self, from: data)
        } catch {
            print("Failed to load DailyEquations.json: \(error)")
        }
    }
    
    private func loadEquationSet(for date: Date) -> DailyEquationSet? {
        let dateKey = Self.dateFormatter.string(from: date)
        
        // Check UserDefaults override first
        if let override = loadEquationSetOverride(for: dateKey) {
            return override
        }
        
        // Check bundled JSON
        return allEquationSets.first { $0.id == dateKey }
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
}

