//
//  StreakManager.swift
//  TestCaliNode
//
//  Centralized streak tracking for workouts, quests, and other activities
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - DateFormatter Extension for Streak Tracking
extension DateFormatter {
    static let streakDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

// MARK: - Streak Data Models

struct StreakData: Codable {
    var currentWorkoutStreak: Int = 0
    var longestWorkoutStreak: Int = 0
    var currentQuestStreak: Int = 0
    var longestQuestStreak: Int = 0
    var lastWorkoutDate: Date?
    var lastQuestCompletionDate: Date?
    var workoutDates: [String] = [] // YYYY-MM-DD format
    var questCompletionDates: [String] = [] // YYYY-MM-DD format
    var totalWorkoutDays: Int = 0
    var totalQuestCompletionDays: Int = 0
    
    // Computed properties for streak analysis
    var isWorkoutStreakActive: Bool {
        guard let lastDate = lastWorkoutDate else { return false }
        let daysSinceLastWorkout = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return daysSinceLastWorkout <= 1 // Allow for today or yesterday
    }
    
    var isQuestStreakActive: Bool {
        guard let lastDate = lastQuestCompletionDate else { return false }
        let daysSinceLastQuest = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return daysSinceLastQuest <= 1 // Allow for today or yesterday
    }
}

// MARK: - Streak Manager

class StreakManager: ObservableObject {
    static let shared = StreakManager()
    
    @Published var streakData = StreakData()
    private let db = Firestore.firestore()
    
    private init() {
        loadStreakData()
    }
    
    // MARK: - Data Loading
    
    private func loadStreakData() {
        guard let user = Auth.auth().currentUser else {
            loadFromUserDefaults()
            return
        }
        
        let streakRef = db.collection("users").document(user.uid).collection("streaks").document("data")
        
        streakRef.getDocument { [weak self] document, error in
            if let error = error {
                print("❌ Error loading streak data: \(error.localizedDescription)")
                self?.loadFromUserDefaults()
                return
            }
            
            DispatchQueue.main.async {
                if let doc = document, doc.exists, let data = doc.data() {
                    self?.streakData = self?.decodeStreakData(from: data) ?? StreakData()
                    print("✅ Loaded streak data from Firebase")
                } else {
                    self?.loadFromUserDefaults()
                }
            }
        }
    }
    
    private func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "streakData"),
           let decoded = try? JSONDecoder().decode(StreakData.self, from: data) {
            streakData = decoded
            print("📱 Loaded streak data from UserDefaults")
        }
    }
    
    // MARK: - Workout Streak Tracking
    
    func recordWorkoutCompletion(date: Date = Date()) {
        let dateString = DateFormatter.streakDateFormatter.string(from: date)
        
        // Only add if not already recorded for this date
        guard !streakData.workoutDates.contains(dateString) else {
            print("⚠️ Workout already recorded for \(dateString)")
            return
        }
        
        streakData.workoutDates.append(dateString)
        streakData.workoutDates.sort() // Keep dates sorted
        streakData.lastWorkoutDate = date
        streakData.totalWorkoutDays = streakData.workoutDates.count
        
        // Recalculate workout streak
        streakData.currentWorkoutStreak = calculateWorkoutStreak()
        streakData.longestWorkoutStreak = max(streakData.longestWorkoutStreak, streakData.currentWorkoutStreak)
        
        saveStreakData()
        
        print("🔥 Workout streak updated: \(streakData.currentWorkoutStreak) days")
    }
    
    func recordQuestCompletion(date: Date = Date()) {
        let dateString = DateFormatter.streakDateFormatter.string(from: date)
        
        // Only add if not already recorded for this date
        guard !streakData.questCompletionDates.contains(dateString) else {
            print("⚠️ Quest completion already recorded for \(dateString)")
            return
        }
        
        streakData.questCompletionDates.append(dateString)
        streakData.questCompletionDates.sort() // Keep dates sorted
        streakData.lastQuestCompletionDate = date
        streakData.totalQuestCompletionDays = streakData.questCompletionDates.count
        
        // Recalculate quest streak
        streakData.currentQuestStreak = calculateQuestStreak()
        streakData.longestQuestStreak = max(streakData.longestQuestStreak, streakData.currentQuestStreak)
        
        saveStreakData()
        
        print("🎯 Quest streak updated: \(streakData.currentQuestStreak) days")
    }
    
    // MARK: - Streak Calculations
    
    private func calculateWorkoutStreak() -> Int {
        return calculateStreakFromDates(streakData.workoutDates)
    }
    
    private func calculateQuestStreak() -> Int {
        return calculateStreakFromDates(streakData.questCompletionDates)
    }
    
    private func calculateStreakFromDates(_ dateStrings: [String]) -> Int {
        guard !dateStrings.isEmpty else { return 0 }
        
        let dates = dateStrings.compactMap { DateFormatter.streakDateFormatter.date(from: $0) }.sorted()
        guard !dates.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        
        // Count backwards from today
        var currentDate = today
        
        for i in stride(from: dates.count - 1, through: 0, by: -1) {
            let date = calendar.startOfDay(for: dates[i])
            
            if calendar.isDate(date, inSameDayAs: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                // If there's a gap, check if it's just one day (yesterday)
                if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                   calendar.isDate(date, inSameDayAs: yesterday) {
                    streak += 1
                }
                break
            }
        }
        
        return streak
    }
    
    // MARK: - Data Persistence
    
    private func saveStreakData() {
        // Save to UserDefaults as backup
        if let data = try? JSONEncoder().encode(streakData) {
            UserDefaults.standard.set(data, forKey: "streakData")
        }
        
        // Save to Firebase
        guard let user = Auth.auth().currentUser else { return }
        
        let streakRef = db.collection("users").document(user.uid).collection("streaks").document("data")
        let data = encodeStreakData(streakData)
        
        streakRef.setData(data) { error in
            if let error = error {
                print("❌ Error saving streak data: \(error.localizedDescription)")
            } else {
                print("✅ Streak data saved to Firebase")
            }
        }
    }
    
    // MARK: - Analytics and Stats
    
    func getWeeklyWorkoutStats() -> [Int] {
        let calendar = Calendar.current
        let today = Date()
        var weeklyStats: [Int] = []
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let dateString = DateFormatter.streakDateFormatter.string(from: date)
            let hasWorkout = streakData.workoutDates.contains(dateString)
            weeklyStats.append(hasWorkout ? 1 : 0)
        }
        
        return weeklyStats.reversed() // Return Monday-Sunday order
    }
    
    func getMonthlyCompletionRate() -> Double {
        let calendar = Calendar.current
        let today = Date()
        
        guard let startOfMonth = calendar.dateInterval(of: .month, for: today)?.start else {
            return 0.0
        }
        
        let daysInMonth = calendar.dateComponents([.day], from: startOfMonth, to: today).day ?? 0
        
        var workoutDaysThisMonth = 0
        for i in 0...daysInMonth {
            guard let date = calendar.date(byAdding: .day, value: i, to: startOfMonth) else { continue }
            let dateString = DateFormatter.streakDateFormatter.string(from: date)
            if streakData.workoutDates.contains(dateString) {
                workoutDaysThisMonth += 1
            }
        }
        
        return Double(workoutDaysThisMonth) / Double(max(daysInMonth, 1))
    }
    
    // MARK: - Encoding/Decoding
    
    private func encodeStreakData(_ data: StreakData) -> [String: Any] {
        return [
            "currentWorkoutStreak": data.currentWorkoutStreak,
            "longestWorkoutStreak": data.longestWorkoutStreak,
            "currentQuestStreak": data.currentQuestStreak,
            "longestQuestStreak": data.longestQuestStreak,
            "lastWorkoutDate": data.lastWorkoutDate != nil ? Timestamp(date: data.lastWorkoutDate!) : NSNull(),
            "lastQuestCompletionDate": data.lastQuestCompletionDate != nil ? Timestamp(date: data.lastQuestCompletionDate!) : NSNull(),
            "workoutDates": data.workoutDates,
            "questCompletionDates": data.questCompletionDates,
            "totalWorkoutDays": data.totalWorkoutDays,
            "totalQuestCompletionDays": data.totalQuestCompletionDays,
            "lastUpdated": Timestamp()
        ]
    }
    
    private func decodeStreakData(from dict: [String: Any]) -> StreakData {
        var data = StreakData()
        
        data.currentWorkoutStreak = dict["currentWorkoutStreak"] as? Int ?? 0
        data.longestWorkoutStreak = dict["longestWorkoutStreak"] as? Int ?? 0
        data.currentQuestStreak = dict["currentQuestStreak"] as? Int ?? 0
        data.longestQuestStreak = dict["longestQuestStreak"] as? Int ?? 0
        data.workoutDates = dict["workoutDates"] as? [String] ?? []
        data.questCompletionDates = dict["questCompletionDates"] as? [String] ?? []
        data.totalWorkoutDays = dict["totalWorkoutDays"] as? Int ?? data.workoutDates.count
        data.totalQuestCompletionDays = dict["totalQuestCompletionDays"] as? Int ?? data.questCompletionDates.count
        
        if let timestamp = dict["lastWorkoutDate"] as? Timestamp {
            data.lastWorkoutDate = timestamp.dateValue()
        }
        
        if let timestamp = dict["lastQuestCompletionDate"] as? Timestamp {
            data.lastQuestCompletionDate = timestamp.dateValue()
        }
        
        return data
    }
    
    // MARK: - Reset Functions
    
    func resetAllStreaks() {
        streakData = StreakData()
        saveStreakData()
        print("🔄 All streaks reset")
    }
    
    func resetWorkoutStreak() {
        streakData.currentWorkoutStreak = 0
        streakData.longestWorkoutStreak = 0
        streakData.workoutDates.removeAll()
        streakData.lastWorkoutDate = nil
        streakData.totalWorkoutDays = 0
        saveStreakData()
        print("🔄 Workout streak reset")
    }
    
    func resetQuestStreak() {
        streakData.currentQuestStreak = 0
        streakData.longestQuestStreak = 0
        streakData.questCompletionDates.removeAll()
        streakData.lastQuestCompletionDate = nil
        streakData.totalQuestCompletionDays = 0
        saveStreakData()
        print("🔄 Quest streak reset")
    }
}

// MARK: - SwiftUI Integration

extension StreakManager {
    func getWorkoutStreakEmoji() -> String {
        switch streakData.currentWorkoutStreak {
        case 0: return "🌱"
        case 1...2: return "🔥"
        case 3...6: return "🚀"
        case 7...13: return "⚡"
        case 14...29: return "💎"
        case 30...99: return "👑"
        default: return "🏆"
        }
    }
    
    func getQuestStreakEmoji() -> String {
        switch streakData.currentQuestStreak {
        case 0: return "🎯"
        case 1...2: return "🏹"
        case 3...6: return "🎖️"
        case 7...13: return "🏅"
        case 14...29: return "🥇"
        case 30...99: return "👑"
        default: return "🏆"
        }
    }
    
    func getStreakMotivationMessage() -> String {
        let workoutStreak = streakData.currentWorkoutStreak
        let questStreak = streakData.currentQuestStreak
        
        if workoutStreak == 0 && questStreak == 0 {
            return "Start your journey today! 🌟"
        } else if workoutStreak >= 7 || questStreak >= 7 {
            return "You're on fire! Keep it up! 🔥"
        } else if workoutStreak >= 3 || questStreak >= 3 {
            return "Great momentum! 🚀"
        } else {
            return "Building habits one day at a time 💪"
        }
    }
}