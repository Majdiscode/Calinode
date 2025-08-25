//
//  QuestSystem.swift
//  TestCaliNode
//
//  Adaptive Quest System with Individual Capability Scaling
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - DateFormatter Extension (if not already defined)
extension DateFormatter {
    static let questDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

// MARK: - Data Models

struct UserCapabilityProfile: Codable {
    var maxPushUps: Int = 0
    var maxPullUps: Int = 0
    var maxPlankSeconds: Int = 0
    var maxSquats: Int = 0
    var fitnessLevel: FitnessLevel = .beginner
    var questDifficultyMultiplier: Double = 1.0
    var lastAssessment: Date = Date()
    var weeklyGoalMultiplier: Double = 0.8 // Start at 80% of max for quests
    
    enum FitnessLevel: String, Codable, CaseIterable {
        case beginner = "beginner"
        case novice = "novice"
        case intermediate = "intermediate"
        case advanced = "advanced"
        
        var title: String {
            switch self {
            case .beginner: return "Beginner"
            case .novice: return "Novice"
            case .intermediate: return "Intermediate"
            case .advanced: return "Advanced"
            }
        }
        
        var emoji: String {
            switch self {
            case .beginner: return "🌱"
            case .novice: return "💪"
            case .intermediate: return "🔥"
            case .advanced: return "⚡"
            }
        }
    }
}

struct Quest: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let emoji: String
    let type: QuestType
    let difficulty: QuestDifficulty
    let targetValue: Int
    let xpReward: Int
    let coinReward: Int
    let expirationDate: Date
    var isCompleted: Bool = false
    var progress: Int = 0
    
    init(title: String, description: String, emoji: String, type: QuestType, difficulty: QuestDifficulty, targetValue: Int, xpReward: Int, coinReward: Int) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.emoji = emoji
        self.type = type
        self.difficulty = difficulty
        self.targetValue = targetValue
        self.xpReward = xpReward
        self.coinReward = coinReward
        self.expirationDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }
    
    var progressPercentage: Double {
        guard targetValue > 0 else { return 0 }
        return min(1.0, Double(progress) / Double(targetValue))
    }
    
    var isExpired: Bool {
        Date() > expirationDate
    }
}

enum QuestType: String, Codable {
    case workoutCompletion = "workout_completion"
    case repsBased = "reps_based"
    case timeBased = "time_based"
    case exploration = "exploration"
    case consistency = "consistency"
    case improvement = "improvement"
}

enum QuestDifficulty: String, Codable {
    case starter = "starter"
    case challenger = "challenger"
    case beastMode = "beast_mode"
    case readinessTest = "readiness_test"
    
    var title: String {
        switch self {
        case .starter: return "STARTER"
        case .challenger: return "CHALLENGER"
        case .beastMode: return "BEAST MODE"
        case .readinessTest: return "READINESS TEST"
        }
    }
    
    var emoji: String {
        switch self {
        case .starter: return "🟢"
        case .challenger: return "🟡"
        case .beastMode: return "🔴"
        case .readinessTest: return "⚡"
        }
    }
    
    var color: String {
        switch self {
        case .starter: return "green"
        case .challenger: return "orange"
        case .beastMode: return "red"
        case .readinessTest: return "purple"
        }
    }
    
    var multiplier: Double {
        switch self {
        case .starter: return 0.5
        case .challenger: return 0.8
        case .beastMode: return 1.2
        case .readinessTest: return 1.5
        }
    }
}

struct SkillReadinessTest: Codable, Identifiable {
    let id: UUID
    let targetSkillId: String
    let targetSkillName: String
    let testTitle: String
    let testDescription: String
    let requirements: [ReadinessRequirement]
    let unlockDate: Date
    var isCompleted: Bool = false
    var completionDate: Date?
    var testResults: [String: Int] = [:]
    
    init(targetSkillId: String, targetSkillName: String, testTitle: String, testDescription: String, requirements: [ReadinessRequirement]) {
        self.id = UUID()
        self.targetSkillId = targetSkillId
        self.targetSkillName = targetSkillName
        self.testTitle = testTitle
        self.testDescription = testDescription
        self.requirements = requirements
        self.unlockDate = Date()
    }
}

struct ReadinessRequirement: Codable {
    let exerciseId: String
    let exerciseName: String
    let targetReps: Int
    let timeLimit: Int // seconds
    let description: String
}

struct UserProgress: Codable {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastWorkoutDate: Date?
    var totalXP: Int = 0
    var caliCoins: Int = 0
    var completedQuests: [String] = [] // Quest IDs
    var questSuccessRate: Double = 0.0
    var allQuestsCompletedToday: Bool = false
    var showTomorrowPreview: Bool = false
    
    // Skill progression tracking
    var recentWorkoutPerformance: [String: [Int]] = [:] // exerciseId: [recent max reps]
    var availableReadinessTests: [SkillReadinessTest] = []
    var completedReadinessTests: [String] = [] // skill IDs
    
    mutating func updateStreak(workoutCompleted: Bool) {
        let today = Calendar.current.startOfDay(for: Date())
        let lastWorkout = lastWorkoutDate.map { Calendar.current.startOfDay(for: $0) }
        
        if workoutCompleted {
            if let lastDate = lastWorkout {
                let daysBetween = Calendar.current.dateComponents([.day], from: lastDate, to: today).day ?? 0
                if daysBetween == 1 {
                    // Consecutive day
                    currentStreak += 1
                } else if daysBetween > 1 {
                    // Streak broken
                    currentStreak = 1
                }
                // Same day workouts don't change streak
            } else {
                // First workout
                currentStreak = 1
            }
            
            longestStreak = max(longestStreak, currentStreak)
            lastWorkoutDate = Date()
        }
    }
}

// MARK: - Quest Manager

class QuestManager: ObservableObject {
    static let shared = QuestManager()
    
    @Published var dailyQuests: [Quest] = []
    @Published var userProfile: UserCapabilityProfile = UserCapabilityProfile()
    @Published var userProgress: UserProgress = UserProgress()
    @Published var hasCompletedAssessment: Bool = false
    
    private let db = Firestore.firestore()
    private var workoutManager: WorkoutManager?
    private var skillManager: GlobalSkillManager?
    
    private init() {
        loadUserData()
        generateDailyQuests()
    }
    
    // MARK: - Setup & Data Loading
    
    func setWorkoutManager(_ manager: WorkoutManager) {
        self.workoutManager = manager
    }
    
    func setSkillManager(_ manager: GlobalSkillManager) {
        self.skillManager = manager
    }
    
    private func loadUserData() {
        guard let user = Auth.auth().currentUser else {
            loadFromUserDefaults()
            return
        }
        
        let userRef = db.collection("users").document(user.uid)
        userRef.getDocument { [weak self] document, error in
            if let error = error {
                print("❌ Error loading user data: \(error.localizedDescription)")
                self?.loadFromUserDefaults()
                return
            }
            
            DispatchQueue.main.async {
                if let document = document, document.exists,
                   let data = document.data() {
                    
                    // Load capability profile
                    if let profileData = data["capabilityProfile"] as? [String: Any] {
                        self?.userProfile = self?.decodeCapabilityProfile(from: profileData) ?? UserCapabilityProfile()
                        self?.hasCompletedAssessment = true
                    }
                    
                    // Load user progress
                    if let progressData = data["userProgress"] as? [String: Any] {
                        self?.userProgress = self?.decodeUserProgress(from: progressData) ?? UserProgress()
                    }
                } else {
                    self?.loadFromUserDefaults()
                }
            }
        }
    }
    
    private func loadFromUserDefaults() {
        if let profileData = UserDefaults.standard.data(forKey: "userCapabilityProfile"),
           let profile = try? JSONDecoder().decode(UserCapabilityProfile.self, from: profileData) {
            userProfile = profile
            hasCompletedAssessment = true
        }
        
        if let progressData = UserDefaults.standard.data(forKey: "userProgress"),
           let progress = try? JSONDecoder().decode(UserProgress.self, from: progressData) {
            userProgress = progress
        }
    }
    
    private func saveUserData() {
        // Save to UserDefaults as backup
        if let profileData = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(profileData, forKey: "userCapabilityProfile")
        }
        
        if let progressData = try? JSONEncoder().encode(userProgress) {
            UserDefaults.standard.set(progressData, forKey: "userProgress")
        }
        
        // Save to Firebase
        guard let user = Auth.auth().currentUser else { return }
        
        let userRef = db.collection("users").document(user.uid)
        let profileDict = encodeCapabilityProfile(userProfile)
        let progressDict = encodeUserProgress(userProgress)
        
        userRef.setData([
            "capabilityProfile": profileDict,
            "userProgress": progressDict,
            "lastUpdated": Timestamp()
        ], merge: true) { error in
            if let error = error {
                print("❌ Error saving user data: \(error.localizedDescription)")
            } else {
                print("✅ User data saved to Firebase")
            }
        }
        
        // Save daily quests separately for better organization
        saveDailyQuestsToFirebase()
    }
    
    // MARK: - Firebase Quest Persistence
    
    private func saveDailyQuestsToFirebase() {
        guard let user = Auth.auth().currentUser else { return }
        guard !dailyQuests.isEmpty else { return }
        
        let dateString = DateFormatter.questDateFormatter.string(from: Date())
        let questsRef = db.collection("users").document(user.uid).collection("quests").document("daily").collection("history").document(dateString)
        
        let questsData = dailyQuests.map { quest in
            return [
                // Basic quest info
                "id": quest.id.uuidString,
                "title": quest.title,
                "description": quest.description,
                "emoji": quest.emoji,
                
                // Quest configuration
                "type": quest.type.rawValue,
                "typeReadable": quest.type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized,
                "difficulty": quest.difficulty.rawValue,
                "difficultyReadable": quest.difficulty.title,
                "difficultyEmoji": quest.difficulty.emoji,
                
                // Progress tracking
                "targetValue": quest.targetValue,
                "currentProgress": quest.progress,
                "progressPercentage": Int(quest.progressPercentage * 100),
                "isCompleted": quest.isCompleted,
                
                // Rewards
                "xpReward": quest.xpReward,
                "coinReward": quest.coinReward,
                "totalRewardValue": quest.xpReward + (quest.coinReward * 10), // Rough value calculation
                
                // Timing
                "expirationDate": Timestamp(date: quest.expirationDate),
                "isExpired": quest.isExpired,
                "completedAt": quest.isCompleted ? Timestamp() : NSNull(),
                
                // Readable summary
                "summary": [
                    "title": quest.title,
                    "status": quest.isCompleted ? "✅ Completed" : (quest.isExpired ? "⏰ Expired" : "🔄 In Progress"),
                    "progress": "\(quest.progress)/\(quest.targetValue)",
                    "reward": "\(quest.xpReward) XP + \(quest.coinReward) coins"
                ]
            ]
        }
        
        let allCompleted = dailyQuests.allSatisfy { $0.isCompleted }
        
        // Break down complex calculations to help compiler
        let completedQuests = dailyQuests.filter { $0.isCompleted }
        let completedCount = completedQuests.count
        let totalCount = dailyQuests.count
        let completionRate = totalCount == 0 ? 0 : Int((Double(completedCount) / Double(totalCount)) * 100)
        let totalXp = completedQuests.reduce(0) { $0 + $1.xpReward }
        let totalCoins = completedQuests.reduce(0) { $0 + $1.coinReward }
        
        let questData: [String: Any] = [
            // Date and timing
            "date": dateString,
            "dateReadable": DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .none),
            "lastUpdated": Timestamp(),
            
            // Quest data
            "quests": questsData,
            
            // Progress summary
            "completedCount": completedCount,
            "totalCount": totalCount,
            "allCompleted": allCompleted,
            "completionRate": completionRate,
            
            // Rewards summary
            "totalXpEarned": totalXp,
            "totalCoinsEarned": totalCoins,
            
            // Difficulty breakdown
            "questsByDifficulty": [
                "starter": dailyQuests.filter { $0.difficulty == .starter }.count,
                "challenger": dailyQuests.filter { $0.difficulty == .challenger }.count,
                "beastMode": dailyQuests.filter { $0.difficulty == .beastMode }.count,
                "readinessTest": dailyQuests.filter { $0.difficulty == .readinessTest }.count
            ],
            
            // Quick summary for easy reading
            "summary": [
                "status": allCompleted ? "🏆 All Quests Completed!" : "🎯 \(completedCount)/\(totalCount) Completed",
                "totalRewards": "\(totalXp) XP + \(totalCoins) coins",
                "questTitles": dailyQuests.map { "\($0.emoji) \($0.title)" }
            ]
        ]
        
        questsRef.setData(questData) { error in
            if let error = error {
                print("❌ Error saving daily quests: \(error.localizedDescription)")
            } else {
                print("✅ Daily quests saved to Firebase for \(dateString)")
            }
        }
    }
    
    private func loadDailyQuestsFromFirebase() {
        guard let user = Auth.auth().currentUser else { return }
        
        let dateString = DateFormatter.questDateFormatter.string(from: Date())
        let questsRef = db.collection("users").document(user.uid).collection("quests").document("daily").collection("history").document(dateString)
        
        questsRef.getDocument { [weak self] document, error in
            if let error = error {
                print("❌ Error loading daily quests: \(error.localizedDescription)")
                return
            }
            
            DispatchQueue.main.async {
                if let doc = document, doc.exists,
                   let data = doc.data(),
                   let questsData = data["quests"] as? [[String: Any]] {
                    
                    let loadedQuests = questsData.compactMap { questDict -> Quest? in
                        self?.decodeQuestFromFirestore(questDict)
                    }
                    
                    if !loadedQuests.isEmpty {
                        self?.dailyQuests = loadedQuests
                        print("✅ Loaded \(loadedQuests.count) daily quests from Firebase")
                    } else {
                        // No saved quests for today, generate new ones
                        self?.generateNewDailyQuests()
                    }
                } else {
                    // No saved quests for today, generate new ones
                    self?.generateNewDailyQuests()
                }
            }
        }
    }
    
    private func decodeQuestFromFirestore(_ data: [String: Any]) -> Quest? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = data["title"] as? String,
              let description = data["description"] as? String,
              let emoji = data["emoji"] as? String,
              let typeString = data["type"] as? String,
              let type = QuestType(rawValue: typeString),
              let difficultyString = data["difficulty"] as? String,
              let difficulty = QuestDifficulty(rawValue: difficultyString),
              let targetValue = data["targetValue"] as? Int,
              let xpReward = data["xpReward"] as? Int,
              let coinReward = data["coinReward"] as? Int,
              let expirationTimestamp = data["expirationDate"] as? Timestamp else {
            return nil
        }
        
        var quest = Quest(title: title, description: description, emoji: emoji, type: type, difficulty: difficulty, targetValue: targetValue, xpReward: xpReward, coinReward: coinReward)
        
        // We can't modify the id since it's let, but we need the same quest structure
        quest.isCompleted = data["isCompleted"] as? Bool ?? false
        quest.progress = data["progress"] as? Int ?? 0
        
        return quest
    }
    
    func loadQuestHistoryForStreakAnalysis(completion: @escaping ([String: Bool]) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion([:])
            return
        }
        
        let historyRef = db.collection("users").document(user.uid).collection("quests").document("daily").collection("history")
        
        // Get last 30 days of quest data for streak analysis
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        historyRef.whereField("lastUpdated", isGreaterThanOrEqualTo: Timestamp(date: thirtyDaysAgo))
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error loading quest history: \(error.localizedDescription)")
                    completion([:])
                    return
                }
                
                var questHistory: [String: Bool] = [:]
                
                snapshot?.documents.forEach { doc in
                    let data = doc.data()
                    if let dateString = data["date"] as? String,
                       let allCompleted = data["allCompleted"] as? Bool {
                        questHistory[dateString] = allCompleted
                    }
                }
                
                completion(questHistory)
            }
    }
    
    // MARK: - Capability Assessment
    
    func completeAssessment(maxPushUps: Int, maxPullUps: Int, maxPlankSeconds: Int, maxSquats: Int) {
        userProfile.maxPushUps = maxPushUps
        userProfile.maxPullUps = maxPullUps
        userProfile.maxPlankSeconds = maxPlankSeconds
        userProfile.maxSquats = maxSquats
        userProfile.lastAssessment = Date()
        
        // Determine fitness level
        userProfile.fitnessLevel = determineFitnessLevel(pushUps: maxPushUps, pullUps: maxPullUps, plankSeconds: maxPlankSeconds, squats: maxSquats)
        
        hasCompletedAssessment = true
        
        // Mark assessment quest as completed
        if let assessmentQuestIndex = dailyQuests.firstIndex(where: { $0.title == "Take the Assessment" }) {
            completeQuest(at: assessmentQuestIndex)
        }
        
        saveUserData()
        generateDailyQuests()
        
        print("✅ Assessment completed - Fitness Level: \(userProfile.fitnessLevel.title)")
    }
    
    private func determineFitnessLevel(pushUps: Int, pullUps: Int, plankSeconds: Int, squats: Int) -> UserCapabilityProfile.FitnessLevel {
        let pushUpScore = pushUps >= 30 ? 3 : (pushUps >= 15 ? 2 : (pushUps >= 5 ? 1 : 0))
        let pullUpScore = pullUps >= 10 ? 3 : (pullUps >= 3 ? 2 : (pullUps >= 1 ? 1 : 0))
        let plankScore = plankSeconds >= 120 ? 3 : (plankSeconds >= 60 ? 2 : (plankSeconds >= 30 ? 1 : 0))
        let squatScore = squats >= 50 ? 3 : (squats >= 25 ? 2 : (squats >= 10 ? 1 : 0))
        
        let averageScore = Double(pushUpScore + pullUpScore + plankScore + squatScore) / 4.0
        
        if averageScore >= 2.5 {
            return .advanced
        } else if averageScore >= 1.5 {
            return .intermediate
        } else if averageScore >= 0.5 {
            return .novice
        } else {
            return .beginner
        }
    }
    
    // MARK: - Quest Generation
    
    func generateDailyQuests() {
        guard hasCompletedAssessment else {
            // Generate simple onboarding quests
            generateOnboardingQuests()
            return
        }
        
        // First try to load today's quests from Firebase
        if Auth.auth().currentUser != nil {
            loadDailyQuestsFromFirebase()
            return
        }
        
        // Fallback to generating new quests
        generateNewDailyQuests()
    }
    
    private func generateNewDailyQuests() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastQuestDate = dailyQuests.first?.expirationDate.addingTimeInterval(-86400) // Subtract 24 hours
        
        // Only generate new quests if we don't have current ones
        if lastQuestDate == nil || !Calendar.current.isDate(lastQuestDate!, inSameDayAs: today) {
            dailyQuests = []
            
            // Generate one quest for each difficulty tier
            dailyQuests.append(generateStarterQuest())
            dailyQuests.append(generateChallengerQuest())
            dailyQuests.append(generateBeastModeQuest())
            
            print("✅ Generated \(dailyQuests.count) daily quests")
            
            // Save new quests to Firebase
            saveDailyQuestsToFirebase()
        }
    }
    
    private func generateOnboardingQuests() {
        dailyQuests = [
            Quest(
                title: "Start Your Journey",
                description: "Complete any workout to begin",
                emoji: "🚀",
                type: .workoutCompletion,
                difficulty: .starter,
                targetValue: 1,
                xpReward: 50,
                coinReward: 10
            ),
            Quest(
                title: "Take the Assessment",
                description: "Complete your fitness assessment",
                emoji: "📊",
                type: .exploration,
                difficulty: .starter,
                targetValue: 1,
                xpReward: 100,
                coinReward: 25
            )
        ]
    }
    
    private func generateStarterQuest() -> Quest {
        // Always prioritize basic consistency for starter quests
        let questOptions = [
            Quest(
                title: "Show Up Today",
                description: "Complete any workout (even 5 minutes counts!)",
                emoji: "🌟",
                type: .workoutCompletion,
                difficulty: .starter,
                targetValue: 1,
                xpReward: 50,
                coinReward: 10
            ),
            Quest(
                title: "Move Your Body", 
                description: "Do any exercise for at least 2 minutes",
                emoji: "🚶‍♀️",
                type: .timeBased,
                difficulty: .starter,
                targetValue: 120, // 2 minutes
                xpReward: 50,
                coinReward: 10
            )
        ]
        
        return questOptions.randomElement() ?? questOptions[0]
    }
    
    private func generateChallengerQuest() -> Quest {
        // Base the quest on user's capability profile
        let targetReps = Int(Double(userProfile.maxPushUps) * userProfile.weeklyGoalMultiplier * QuestDifficulty.challenger.multiplier)
        
        if userProfile.maxPushUps > 0 {
            return Quest(
                title: "Push Your Limits",
                description: "Complete \(max(targetReps, 5)) push-ups total",
                emoji: "🔥",
                type: .repsBased,
                difficulty: .challenger,
                targetValue: max(targetReps, 5),
                xpReward: 100,
                coinReward: 20
            )
        } else {
            return Quest(
                title: "Workout Strong",
                description: "Workout for 15+ minutes",
                emoji: "⏱️",
                type: .timeBased,
                difficulty: .challenger,
                targetValue: 900, // 15 minutes in seconds
                xpReward: 100,
                coinReward: 20
            )
        }
    }
    
    private func generateBeastModeQuest() -> Quest {
        // Challenge the user to beat their personal best
        if userProfile.maxPushUps > 0 {
            let targetReps = Int(Double(userProfile.maxPushUps) * 1.1) // 10% more than their max
            return Quest(
                title: "Beat Your Best",
                description: "Do \(targetReps)+ push-ups (beat your \(userProfile.maxPushUps) record!)",
                emoji: "👑",
                type: .improvement,
                difficulty: .beastMode,
                targetValue: targetReps,
                xpReward: 200,
                coinReward: 50
            )
        } else {
            return Quest(
                title: "Epic Session",
                description: "Complete a 30+ minute workout",
                emoji: "🏆",
                type: .timeBased,
                difficulty: .beastMode,
                targetValue: 1800, // 30 minutes in seconds
                xpReward: 200,
                coinReward: 50
            )
        }
    }
    
    // MARK: - Readiness Test System
    
    func checkForReadinessTests(from workout: ActiveWorkout) {
        // Track recent performance
        for exercise in workout.exercises {
            let maxReps = exercise.sets.compactMap { $0.reps }.max() ?? 0
            if maxReps > 0 {
                updateRecentPerformance(exerciseId: exercise.exerciseID, maxReps: maxReps)
            }
        }
        
        // Check if user is ready for muscle up test
        if shouldOfferMuscleUpTest() && !userProgress.completedReadinessTests.contains("muscle_up") {
            let muscleUpTest = createMuscleUpReadinessTest()
            if !userProgress.availableReadinessTests.contains(where: { $0.targetSkillId == "muscle_up" }) {
                userProgress.availableReadinessTests.append(muscleUpTest)
                print("🚀 New readiness test available: Muscle Up!")
            }
        }
    }
    
    private func updateRecentPerformance(exerciseId: String, maxReps: Int) {
        if userProgress.recentWorkoutPerformance[exerciseId] == nil {
            userProgress.recentWorkoutPerformance[exerciseId] = []
        }
        
        userProgress.recentWorkoutPerformance[exerciseId]?.append(maxReps)
        
        // Keep only last 10 workouts
        if let count = userProgress.recentWorkoutPerformance[exerciseId]?.count, count > 10 {
            userProgress.recentWorkoutPerformance[exerciseId] = Array(userProgress.recentWorkoutPerformance[exerciseId]!.suffix(10))
        }
    }
    
    private func shouldOfferMuscleUpTest() -> Bool {
        // Check if user has been consistently doing pull-ups and dips
        let pullUpPerformance = userProgress.recentWorkoutPerformance["pull_up"] ?? []
        let dipPerformance = userProgress.recentWorkoutPerformance["diamond_push_up"] ?? [] // Using diamond push-ups as dip substitute
        
        // Need at least 5 recent workouts with both exercises
        guard pullUpPerformance.count >= 5, dipPerformance.count >= 5 else { return false }
        
        // Check average performance over recent workouts
        let avgPullUps = Double(pullUpPerformance.suffix(5).reduce(0, +)) / 5.0
        let avgDips = Double(dipPerformance.suffix(5).reduce(0, +)) / 5.0
        
        // Muscle up readiness criteria: 8+ pull-ups and 15+ dips consistently
        return avgPullUps >= 8 && avgDips >= 15
    }
    
    private func createMuscleUpReadinessTest() -> SkillReadinessTest {
        let requirements = [
            ReadinessRequirement(
                exerciseId: "pull_up",
                exerciseName: "Pull-ups",
                targetReps: 10,
                timeLimit: 180, // 3 minutes
                description: "Complete 10 pull-ups within 3 minutes (can be broken into sets)"
            ),
            ReadinessRequirement(
                exerciseId: "diamond_push_up",
                exerciseName: "Dips/Diamond Push-ups",
                targetReps: 20,
                timeLimit: 180, // 3 minutes
                description: "Complete 20 dips or diamond push-ups within 3 minutes"
            )
        ]
        
        return SkillReadinessTest(
            targetSkillId: "muscle_up",
            targetSkillName: "Muscle Up",
            testTitle: "Muscle Up Readiness Test",
            testDescription: "Your recent performance suggests you might be ready for a muscle up! Complete this test to unlock the muscle up skill progression.",
            requirements: requirements
        )
    }
    
    func completeReadinessTest(_ test: SkillReadinessTest, results: [String: Int]) -> Bool {
        // Check if all requirements were met
        let testPassed = test.requirements.allSatisfy { requirement in
            let actualReps = results[requirement.exerciseId] ?? 0
            return actualReps >= requirement.targetReps
        }
        
        if testPassed {
            userProgress.completedReadinessTests.append(test.targetSkillId)
            // Remove from available tests
            userProgress.availableReadinessTests.removeAll { $0.id == test.id }
            
            // Schedule skill attempt reminder quest for 1-2 days later
            scheduleSkillAttemptQuest(skillId: test.targetSkillId, skillName: test.targetSkillName)
            
            print("🏆 Readiness test passed! \(test.targetSkillName) skill progression unlocked!")
            return true
        } else {
            print("💪 Keep training! You'll get there soon.")
            return false
        }
    }
    
    private func scheduleSkillAttemptQuest(skillId: String, skillName: String) {
        // This would create a special quest that appears in 1-2 days encouraging the user to attempt the new skill
        print("🎯 \(skillName) attempt quest scheduled for 1-2 days from now!")
    }
    
    // MARK: - Quest Progress Tracking
    
    func updateQuestProgress(from workout: ActiveWorkout) {
        // First check for readiness tests
        checkForReadinessTests(from: workout)
        let workoutDuration = workout.endTime?.timeIntervalSince(workout.startTime) ?? 0
        let totalPushUps = getTotalRepsForExercise("push_up", in: workout)
        
        for i in 0..<dailyQuests.count {
            if dailyQuests[i].isCompleted { continue }
            
            switch dailyQuests[i].type {
            case .workoutCompletion:
                if workout.isCompleted {
                    dailyQuests[i].progress = 1
                    completeQuest(at: i)
                }
                
            case .timeBased:
                dailyQuests[i].progress = Int(workoutDuration)
                if dailyQuests[i].progress >= dailyQuests[i].targetValue {
                    completeQuest(at: i)
                }
                
            case .repsBased, .improvement:
                dailyQuests[i].progress = totalPushUps
                if dailyQuests[i].progress >= dailyQuests[i].targetValue {
                    completeQuest(at: i)
                    
                    // Update personal best if it's an improvement quest
                    if dailyQuests[i].type == .improvement && totalPushUps > userProfile.maxPushUps {
                        userProfile.maxPushUps = totalPushUps
                        saveUserData()
                    }
                }
                
            case .exploration:
                // This would need more sophisticated tracking
                // For now, any completed workout counts
                if workout.isCompleted {
                    dailyQuests[i].progress = 1
                    completeQuest(at: i)
                }
                
            case .consistency:
                // Handle streak-based quests
                break
            }
        }
        
        // Update user progress
        userProgress.updateStreak(workoutCompleted: workout.isCompleted)
        saveUserData()
    }
    
    private func getTotalRepsForExercise(_ exerciseId: String, in workout: ActiveWorkout) -> Int {
        return workout.exercises
            .filter { $0.exerciseID == exerciseId }
            .flatMap { $0.sets }
            .compactMap { $0.reps }
            .reduce(0, +)
    }
    
    private func completeQuest(at index: Int) {
        dailyQuests[index].isCompleted = true
        userProgress.totalXP += dailyQuests[index].xpReward
        userProgress.caliCoins += dailyQuests[index].coinReward
        userProgress.completedQuests.append(dailyQuests[index].id.uuidString)
        
        // Update success rate
        let recentQuests = userProgress.completedQuests.suffix(10)
        userProgress.questSuccessRate = Double(recentQuests.count) / 10.0
        
        // Check if all quests are now completed
        let allCompleted = dailyQuests.allSatisfy { $0.isCompleted }
        if allCompleted && !userProgress.allQuestsCompletedToday {
            userProgress.allQuestsCompletedToday = true
            userProgress.showTomorrowPreview = true
            
            // Record quest completion for streak tracking
            StreakManager.shared.recordQuestCompletion()
            
            print("🏆 ALL QUESTS COMPLETED! Tomorrow preview unlocked!")
        }
        
        print("🎉 Quest completed: \(dailyQuests[index].title) (+\(dailyQuests[index].xpReward) XP, +\(dailyQuests[index].coinReward) coins)")
    }
    
    // MARK: - Utility Functions
    
    var completedQuestsToday: Int {
        dailyQuests.filter { $0.isCompleted }.count
    }
    
    var totalQuestsToday: Int {
        dailyQuests.count
    }
    
    func refreshAvailableQuests() {
        generateDailyQuests()
    }
    
    // MARK: - Encoding/Decoding Helpers
    
    private func encodeCapabilityProfile(_ profile: UserCapabilityProfile) -> [String: Any] {
        return [
            "maxPushUps": profile.maxPushUps,
            "maxPullUps": profile.maxPullUps,
            "maxPlankSeconds": profile.maxPlankSeconds,
            "maxSquats": profile.maxSquats,
            "fitnessLevel": profile.fitnessLevel.rawValue,
            "questDifficultyMultiplier": profile.questDifficultyMultiplier,
            "lastAssessment": Timestamp(date: profile.lastAssessment),
            "weeklyGoalMultiplier": profile.weeklyGoalMultiplier
        ]
    }
    
    private func decodeCapabilityProfile(from dict: [String: Any]) -> UserCapabilityProfile {
        var profile = UserCapabilityProfile()
        profile.maxPushUps = dict["maxPushUps"] as? Int ?? 0
        profile.maxPullUps = dict["maxPullUps"] as? Int ?? 0
        profile.maxPlankSeconds = dict["maxPlankSeconds"] as? Int ?? 0
        profile.maxSquats = dict["maxSquats"] as? Int ?? 0
        profile.questDifficultyMultiplier = dict["questDifficultyMultiplier"] as? Double ?? 1.0
        profile.weeklyGoalMultiplier = dict["weeklyGoalMultiplier"] as? Double ?? 0.8
        
        if let levelString = dict["fitnessLevel"] as? String,
           let level = UserCapabilityProfile.FitnessLevel(rawValue: levelString) {
            profile.fitnessLevel = level
        }
        
        if let timestamp = dict["lastAssessment"] as? Timestamp {
            profile.lastAssessment = timestamp.dateValue()
        }
        
        return profile
    }
    
    private func encodeUserProgress(_ progress: UserProgress) -> [String: Any] {
        return [
            "currentStreak": progress.currentStreak,
            "longestStreak": progress.longestStreak,
            "lastWorkoutDate": progress.lastWorkoutDate != nil ? Timestamp(date: progress.lastWorkoutDate!) : NSNull(),
            "totalXP": progress.totalXP,
            "caliCoins": progress.caliCoins,
            "completedQuests": progress.completedQuests,
            "questSuccessRate": progress.questSuccessRate
        ]
    }
    
    private func decodeUserProgress(from dict: [String: Any]) -> UserProgress {
        var progress = UserProgress()
        progress.currentStreak = dict["currentStreak"] as? Int ?? 0
        progress.longestStreak = dict["longestStreak"] as? Int ?? 0
        progress.totalXP = dict["totalXP"] as? Int ?? 0
        progress.caliCoins = dict["caliCoins"] as? Int ?? 0
        progress.completedQuests = dict["completedQuests"] as? [String] ?? []
        progress.questSuccessRate = dict["questSuccessRate"] as? Double ?? 0.0
        
        if let timestamp = dict["lastWorkoutDate"] as? Timestamp {
            progress.lastWorkoutDate = timestamp.dateValue()
        }
        
        return progress
    }
    
    // MARK: - Legacy Compatibility Methods
    
    func updateQuestProgress(skillUnlocked: String) {
        // Keep for compatibility
    }
    
    func triggerFoundationalSkillUnlock() {
        // Keep for compatibility
    }
    
    func triggerBranchCompletion(branchID: String, treeID: String) {
        // Keep for compatibility
    }
    
    func triggerMasterSkillUnlock(skillID: String) {
        // Keep for compatibility
    }
    
    func triggerTreeCompletion(treeID: String) {
        // Keep for compatibility
    }
    
    func resetAllQuests() {
        dailyQuests.removeAll()
        userProgress = UserProgress()
        userProfile = UserCapabilityProfile()
        hasCompletedAssessment = false
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "userCapabilityProfile")
        UserDefaults.standard.removeObject(forKey: "userProgress")
        
        // Clear Firebase quest data
        clearFirebaseQuestData()
        
        print("🎯 All quest data reset")
    }
    
    private func clearFirebaseQuestData() {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)
        
        // Clear quest-related fields from main user document
        userRef.updateData([
            "capabilityProfile": FieldValue.delete(),
            "userProgress": FieldValue.delete()
        ]) { error in
            if let error = error {
                print("❌ Error clearing quest data: \(error.localizedDescription)")
            } else {
                print("✅ Firebase quest data cleared")
            }
        }
        
        // Clear quest subcollections
        userRef.collection("quests").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error getting quest documents: \(error.localizedDescription)")
                return
            }
            
            let batch = db.batch()
            snapshot?.documents.forEach { document in
                batch.deleteDocument(document.reference)
            }
            
            batch.commit { error in
                if let error = error {
                    print("❌ Error deleting quest documents: \(error.localizedDescription)")
                } else {
                    print("✅ Quest history cleared from Firebase")
                }
            }
        }
    }
    
    func resetQuestProgress() {
        dailyQuests.forEach { quest in
            var modifiedQuest = quest
            modifiedQuest.isCompleted = false
            modifiedQuest.progress = 0
        }
    }
}
