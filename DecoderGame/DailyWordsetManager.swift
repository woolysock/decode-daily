//
//  DailyWordsetManager.swift
//  Decode! Daily iOS
//
//  Manages daily wordsets loaded from a bundled JSON file (DailyWordsets.json).
//  Falls back to generating a set from a bundled MasterWordList.json (or a small in-code fallback).
//

import Foundation
import Combine

struct WordsetGenerationProgress: Codable {
    var lastGeneratedDate: Date?
    var usedWords: Set<String> = []
    var totalWordsGenerated: Int = 0
}

final class DailyWordsetManager: ObservableObject {
    // MARK: - Singleton
    static let shared = DailyWordsetManager()
    
    // MARK: - Published
    @Published var currentWordset: DailyWordset?
    @Published var isGeneratingWordsets: Bool = false
    @Published var generationProgress: Double = 0.0   // 0.0 .. 1.0 (informational)
    
    // MARK: - Private state to prevent infinite loops
    private var isLoadingTodaysWordset = false

    // MARK: - Private storage keys & resources
    private let userDefaults = UserDefaults.standard
    private let wordsetsKey = "DailyWordsets"               // used for per-day overrides: "\(wordsetsKey)_YYYY-MM-DD"
    private let progressKey = "WordsetGenerationProgress"  // generation progress saved in UserDefaults
    private let dailyWordsetsResource = "DailyWordsets"    // expects DailyWordsets.json in bundle
    private let masterWordListResource = "MasterWordList"  // expects MasterWordList.json in bundle (array of strings)

    // MARK: - In-memory caches
    /// `allWordsets` is loaded from the bundled JSON file (DailyWordsets.json).
    private(set) var allWordsets: [DailyWordset] = []
    /// Master list used to generate new wordsets when a date is missing from JSON
    private(set) var masterWordList: [String] = []

    // MARK: - Date formatter (yyyy-MM-dd)
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    // MARK: - Init
    private init() { // Make init private for singleton
        loadAllWordsets()
        loadMasterWordList()
        loadTodaysWordset()
    }

    // MARK: - Public API

    /// Call this when a new day is detected to refresh the current wordset
    func refreshForNewDay() {
        print("DailyWordsetManager: Refreshing for new day")
        
        // Ensure all UI updates happen on main thread
        DispatchQueue.main.async { [weak self] in
            // Clear any cached wordset data and reset loading state
            self?.currentWordset = nil
            self?.isLoadingTodaysWordset = false
            
            // Force regenerate/reload today's wordset
            self?.loadTodaysWordset()
        }
    }

    /// Ensures today's wordset is loaded into `currentWordset`.
    func loadTodaysWordset() {
        guard !isLoadingTodaysWordset else { return }
        
        let today = Calendar.current.startOfDay(for: Date())
        isLoadingTodaysWordset = true
        
        if let wordset = loadWordset(for: today) {
            DispatchQueue.main.async { [weak self] in
                self?.currentWordset = wordset
                self?.isLoadingTodaysWordset = false
            }
        } else {
            generateWordsetForDate(today)
            isLoadingTodaysWordset = false
        }
    }
    
    /// Return the current cached wordset (if any)
    func getTodaysWordset(for date: Date) -> DailyWordset? {
        let requestedDate = Calendar.current.startOfDay(for: date) // normalize to local start of day
        let today = Calendar.current.startOfDay(for: Date())
        
        // Debug
        print("getTodaysWordset -> requestedDate: \(requestedDate), today: \(today)")
        
        if Calendar.current.isDate(requestedDate, inSameDayAs: today) {
            return currentWordset
        }
        
        // For archive dates, load the specific wordset
        if let archiveWordset = getWordset(for: requestedDate) {
            print("Archive wordset found for: \(requestedDate)")
            return archiveWordset
        }
        
        print("No wordset found for: \(requestedDate)")
        return nil
    }

    /// Return a wordset for a given date (may be an override saved to UserDefaults, or one loaded from the bundled JSON)
    func getWordset(for date: Date) -> DailyWordset? {
        return loadWordset(for: date)
    }

    /// Generate a wordset for the date (async). This mirrors the old behavior:
    /// - sets isGeneratingWordsets and generationProgress
    /// - picks random words avoiding recently-used words (via generation progress)
    /// - saves result to UserDefaults as an override and publishes currentWordset
    func generateWordsetForDate(_ date: Date, count: Int = 10) {
        // Use async dispatch to avoid "Publishing changes from within view updates" warning
        DispatchQueue.main.async { [weak self] in
            self?.isGeneratingWordsets = true
            self?.generationProgress = 0.0
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Update progress on main queue, but asynchronously
            DispatchQueue.main.async {
                self.generationProgress = 0.05
            }

            let selectedWords = self.selectRandomWords(count: count)

            // Final update - also async to avoid synchronous publishing
            DispatchQueue.main.async {
                let wordset = DailyWordset(date: date, words: selectedWords)
                self.saveWordset(wordset)
                self.currentWordset = wordset
                self.isGeneratingWordsets = false
                self.generationProgress = 1.0
            }
        }
    }

    /// Mark the current (cached) wordset as completed with a given score
    func markWordsetCompleted(score: Int) {
        guard var wordset = currentWordset else { return }
        wordset.isCompleted = true
        wordset.completedAt = Date()
        saveWordset(wordset)
        
        // Use async dispatch to avoid publishing during view updates
        DispatchQueue.main.async { [weak self] in
            self?.currentWordset = wordset
        }
    }

    /// Mark an arbitrary wordset as completed (keeps expected API)
    func markWordsetCompleted(_ wordset: DailyWordset, score: Int) {
        var updatedWordset = wordset
        updatedWordset.isCompleted = true
        updatedWordset.completedAt = Date()
        saveWordset(updatedWordset)

        // Use async dispatch to avoid publishing during view updates
        DispatchQueue.main.async { [weak self] in
            if self?.currentWordset?.id == wordset.id {
                self?.currentWordset = updatedWordset
            }
        }
    }

    /// Returns the available date range. If there are bundled JSON wordsets, the range is from the first JSON entry's date to the last.
    /// Otherwise defaults to (today - 30 days) ... today.
    func getAvailableDateRange() -> ClosedRange<Date> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if !allWordsets.isEmpty {
            // We assume the JSON is pre-sorted by date (user requested no programmatic resorting).
            let first = allWordsets.first!.date
            let last = allWordsets.last!.date
            return first...last
        } else {
            let past = calendar.date(byAdding: .day, value: -30, to: today) ?? today
            return past...today
        }
    }

    // MARK: - Private helpers

    /// Select `count` random words from masterWordList, avoiding words in the used-words progress.
    /// Persists progress so words are not repeated until list is exhausted.
    private func selectRandomWords(count: Int) -> [String] {
        var availableWords = masterWordList
        var selectedWords: [String] = []

        var progress = loadGenerationProgress()

        // Remove used words
        availableWords = availableWords.filter { !progress.usedWords.contains($0) }

        // If we're running low, reset used words
        if availableWords.count < count {
            progress.usedWords.removeAll()
            availableWords = masterWordList
        }

        // Select random words
        for _ in 0..<count {
            guard !availableWords.isEmpty else { break }
            let idx = Int.random(in: 0..<availableWords.count)
            let chosen = availableWords.remove(at: idx)
            selectedWords.append(chosen)
            progress.usedWords.insert(chosen)
        }

        progress.totalWordsGenerated += selectedWords.count
        progress.lastGeneratedDate = Date()
        saveGenerationProgress(progress)

        return selectedWords
    }

    /// Loads a wordset for the date. Checks UserDefaults (overrides) first, then bundled JSON array.
    private func loadWordset(for date: Date) -> DailyWordset? {
        let dateKey = Self.dateFormatter.string(from: date)
        print("🔍 Looking for wordset with dateKey: \(dateKey)")

        // Skip UserDefaults - go directly to bundled JSON
        
        print("🔍 Searching in \(allWordsets.count) bundled wordsets...")
        if let found = allWordsets.first(where: { $0.id == dateKey }) {
            print("✅ Found wordset in bundled JSON for \(dateKey): \(found.words)")
            return found
        }

        print("❌ No wordset found for \(dateKey)")
        return nil
    }

    /// Saves a wordset as an override into UserDefaults (does not and should not mutate the bundled JSON).
    private func saveWordset(_ wordset: DailyWordset) {
        let key = "\(wordsetsKey)_\(wordset.id)"
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(Self.dateFormatter)
        do {
            let data = try encoder.encode(wordset)
            userDefaults.set(data, forKey: key)
        } catch {
            print("DailyWordsetManager - failed to encode wordset for \(wordset.id): \(error)")
        }
    }

    /// Loads an override wordset from UserDefaults (if user has completed or modified a day)
    private func loadWordsetOverride(for dateKey: String) -> DailyWordset? {
        let key = "\(wordsetsKey)_\(dateKey)"
        guard let data = userDefaults.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(Self.dateFormatter)
        do {
            let ws = try decoder.decode(DailyWordset.self, from: data)
            return ws
        } catch {
            print("DailyWordsetManager - failed to decode override for \(key): \(error)")
            return nil
        }
    }

    // MARK: - Generation progress load/save

    private func loadGenerationProgress() -> WordsetGenerationProgress {
        guard let data = userDefaults.data(forKey: progressKey) else {
            return WordsetGenerationProgress()
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(Self.dateFormatter)
        do {
            let p = try decoder.decode(WordsetGenerationProgress.self, from: data)
            return p
        } catch {
            print("DailyWordsetManager - failed to decode generation progress: \(error)")
            return WordsetGenerationProgress()
        }
    }

    private func saveGenerationProgress(_ progress: WordsetGenerationProgress) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(Self.dateFormatter)
        do {
            let data = try encoder.encode(progress)
            userDefaults.set(data, forKey: progressKey)
        } catch {
            print("DailyWordsetManager - failed to encode generation progress: \(error)")
        }
    }

    // MARK: - Load bundled JSON resources

    /// Loads DailyWordsets.json from the app bundle into `allWordsets`.
    /// IMPORTANT: this function does NOT re-sort the array; it uses the order in the JSON file.
    private func loadAllWordsets() {
        guard let url = Bundle.main.url(forResource: dailyWordsetsResource, withExtension: "json") else {
            print("DailyWordsetManager - no \(dailyWordsetsResource).json found in bundle.")
            return
        }
        
        print("✅ Found DailyWordset.json at: \(url)")

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(Self.dateFormatter)
            let wordsets = try decoder.decode([DailyWordset].self, from: data)
            self.allWordsets = wordsets
        } catch {
            print("DailyWordsetManager - failed to load/parse \(dailyWordsetsResource).json: \(error)")
        }
    }

    /// Loads a master list of words from MasterWordList.json (array of strings).
    /// If not present, falls back to a small built-in list so generation still works.
    private func loadMasterWordList() {
        guard let url = Bundle.main.url(forResource: masterWordListResource, withExtension: "json") else {
            print("DailyWordsetManager - no \(masterWordListResource).json, using fallback master list.")
            self.masterWordList = Self.defaultMasterWordList()
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let arr = try decoder.decode([String].self, from: data)
            // normalize to uppercase
            self.masterWordList = arr.map { $0.uppercased() }
        } catch {
            print("DailyWordsetManager - failed to load/parse \(masterWordListResource).json: \(error)")
            self.masterWordList = Self.defaultMasterWordList()
        }
    }

    // Small fallback list — only used if you don't add MasterWordList.json to the bundle.
    private static func defaultMasterWordList() -> [String] {
        return [
            "APPLE","ABOUT","ARISE","BRAVE","BREAD","CLOUD","CABLE","DRIVE","EVENT","FABLE",
            "GHOST","HONEY","INDEX","JOKER","KNIFE","LIGHT","MONEY","NIGHT","OFFER","POINT",
            "QUEST","RIVER","SCOPE","TRAIN","UNITY","VALUE","WATER","YOUTH","ZEBRA","SPEAK"
        ]
    }
    
    func getAvailableDates() -> [Date] {
        // Map the loaded JSON sets to their actual dates
        let dates = allWordsets.map { $0.date }
        return dates.sorted(by: >) // newest first
    }

}
