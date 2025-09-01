//
//  DailyCodeSetManager.swift
//  Decode! Daily iOS
//
//  Created by Megan Donahue
//

import Foundation
import Combine

struct DailyCodeSet: Codable, Identifiable {
    var id: String
    var date: Date
    var peg1: Int
    var peg2: Int
    var peg3: Int
    var peg4: Int
    var peg5: Int
}

final class DailyCodeSetManager: ObservableObject {
    static let shared = DailyCodeSetManager()
    
    @Published var currentCodeSet: DailyCodeSet?
    @Published var isGeneratingCodes: Bool = false
    @Published var generationProgress: Double = 0.0
    
    private let userDefaults = UserDefaults.standard
    private let codeSetsKey = "DailyCodeSets"
    private let dailyCodesResource = "DailyCodes" // DailyCodes.json
    
    private var isLoadingTodaysSet = false
    private(set) var allCodeSets: [DailyCodeSet] = []
    
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    
    private init() {
        loadAllCodeSets()
        loadTodaysCodeSet()
    }
    
    func refreshForNewDay() {
        print("DailyCodeSetManager: Refreshing for new day")
        DispatchQueue.main.async { [weak self] in
            self?.currentCodeSet = nil
            self?.isLoadingTodaysSet = false
            self?.loadTodaysCodeSet()
        }
    }
    
    func loadTodaysCodeSet() {
        guard !isLoadingTodaysSet else { return }
        
        let today = Calendar.current.startOfDay(for: Date())
        isLoadingTodaysSet = true
        
        if let codeSet = loadCodeSet(for: today) {
            print("✅ Found existing color codeset for today, with date \(codeSet.date)")
            DispatchQueue.main.async { [weak self] in
                self?.currentCodeSet = codeSet
                self?.isLoadingTodaysSet = false
            }
        } else {
            print("🔄 No existing code set found for today, generating new one...")
            generateCodeSetForDate(today)
            isLoadingTodaysSet = false
        }
    }
    
    func getTodaysCodeSet(for date: Date) -> DailyCodeSet? {
        let requestedDate = Calendar.current.startOfDay(for: date)
        let today = Calendar.current.startOfDay(for: Date())
        
        // Debug
        print("getTodaysCodeSet -> requestedDate: \(requestedDate), today: \(today)")
        
        // For today's date, use the cached currentCodeSet if available
        if Calendar.current.isDate(requestedDate, inSameDayAs: today) {
            if let current = currentCodeSet {
                print("📋 Using cached currentCodeSet: [\(current.peg1),\(current.peg2),\(current.peg3),\(current.peg4),\(current.peg5)]")
                return current
            }
        }
        
        // For any date (including today if not cached), load from JSON
        if let codeSet = getCodeSet(for: requestedDate) {
            print("📅 Found Code set for: \(requestedDate) - [\(codeSet.peg1),\(codeSet.peg2),\(codeSet.peg3),\(codeSet.peg4),\(codeSet.peg5)]")
            
            // Cache it if it's for today
            if Calendar.current.isDate(requestedDate, inSameDayAs: today) {
                DispatchQueue.main.async { [weak self] in
                    self?.currentCodeSet = codeSet
                }
            }
            
            return codeSet
        }
        
        print("❌ No Code set found for: \(requestedDate)")
        return nil
    }
    
    // Private methods similar to DailyWordsetManager...
    private func loadAllCodeSets() {
        print("🔍 Looking for DailyCodes.json in bundle...")
        
        guard let url = Bundle.main.url(forResource: dailyCodesResource, withExtension: "json") else {
            print("❌ DailyCodeManager - no DailyCode.json found in bundle")
            print("📂 Available files: \(Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? [])")
            return
        }
        
        print("✅ Found DailyCode.json at: \(url)")
        
        do {
            let data = try Data(contentsOf: url)
            print("📊 JSON file size: \(data.count) bytes")
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(Self.dateFormatter)
            self.allCodeSets = try decoder.decode([DailyCodeSet].self, from: data)
            
            print("✅ Successfully loaded \(allCodeSets.count) Code sets")
            if let first = allCodeSets.first {
                print("📝 First set: \(first.id) : [\(first.peg1),\(first.peg2),\(first.peg3),\(first.peg4),\(first.peg5)]")
            }
            
            // Debug: Print all loaded dates
            print("🗓️ All loaded dates:")
            for codeSet in allCodeSets {
                print("   - \(codeSet.id): [\(codeSet.peg1),\(codeSet.peg2),\(codeSet.peg3),\(codeSet.peg4),\(codeSet.peg5)]")
            }
        } catch {
            print("❌ Failed to load/parse DailyCodes.json: \(error)")
        }
    }
    
    private func loadCodeSet(for date: Date) -> DailyCodeSet? {
        let dateKey = Self.dateFormatter.string(from: date)
        print("🔍 Looking for Code set with dateKey: \(dateKey)")
        
        // Search in bundled JSON using the dateKey as ID
        print("🔍 Searching in \(allCodeSets.count) bundled code sets...")
        if let found = allCodeSets.first(where: { $0.id == dateKey }) {
            print("✅ Found Code set in bundled JSON for \(dateKey): [\(found.peg1),\(found.peg2),\(found.peg3),\(found.peg4),\(found.peg5)]")
            return found
        }

        print("❌ No Code set found for \(dateKey)")
        return nil
    }
    
    private func generateCode(for date: Date) -> DailyCodeSet {
        return DailyCodeSet(
            id: Self.dateFormatter.string(from: date),
            date: date,
            peg1: Int.random(in: 1...6),
            peg2: Int.random(in: 1...6),
            peg3: Int.random(in: 1...6),
            peg4: Int.random(in: 1...6),
            peg5: Int.random(in: 1...6)
        )
    }
    
    // Additional helper methods for saving/loading...
    private func generateCodeSetForDate(_ date: Date) {
        DispatchQueue.main.async { [weak self] in
            self?.isGeneratingCodes = true
            self?.generationProgress = 0.0
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let codeSet = self.generateCode(for: date)

            DispatchQueue.main.async {
                self.saveCodeSet(codeSet)
                self.currentCodeSet = codeSet
                self.isGeneratingCodes = false
                self.generationProgress = 1.0
            }
        }
    }

    private func generateRandomCodes(count: Int) -> [DailyCodeSet] {
        var these_codes: [DailyCodeSet] = []
        
        for i in 0..<count {
            let date = Calendar.current.date(byAdding: .day, value: i, to: Date()) ?? Date()
            let code = generateCode(for: date)
            these_codes.append(code)
        }
        
        return these_codes
    }

    private func loadCodeSetOverride(for dateKey: String) -> DailyCodeSet? {
        let key = "\(codeSetsKey)_\(dateKey)"
        guard let data = userDefaults.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(Self.dateFormatter)
        do {
            return try decoder.decode(DailyCodeSet.self, from: data)
        } catch {
            print("DailyCodeManager - failed to decode override for \(key): \(error)")
            return nil
        }
    }

    private func saveCodeSet(_ codeSet: DailyCodeSet) {
        let key = "\(codeSetsKey)_\(codeSet.id)"
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(Self.dateFormatter)
        do {
            let data = try encoder.encode(codeSet)
            userDefaults.set(data, forKey: key)
        } catch {
            print("DailyCodeManager - failed to encode code set for \(codeSet.id): \(error)")
        }
    }
    
    func getAvailableDates() -> [Date] {
        // Map the loaded JSON sets to their actual dates
        let dates = allCodeSets.map { $0.date }
        return dates.sorted(by: >) // newest first
    }
    
    func getCodeSet(for date: Date) -> DailyCodeSet? {
        return loadCodeSet(for: date)
    }
}
