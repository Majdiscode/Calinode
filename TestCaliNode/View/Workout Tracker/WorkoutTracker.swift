//
//  WorkoutTracker.swift
//  TestCaliNode
//
//  Enhanced workout tracking system with reliable Firebase integration
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - DateFormatter Extension for Streak Tracking
extension DateFormatter {
    static let workoutDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

// MARK: - Keyboard Dismissal Helper
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Data Models

enum ExerciseType: String, Codable, CaseIterable {
    case reps = "reps"
    case time = "time"
    case distance = "distance"
}

struct Exercise: Identifiable, Codable {
    let id: String
    let name: String
    let type: ExerciseType
    let category: String
    let description: String
    let emoji: String
    let difficulty: Int
}

struct WorkoutSet: Identifiable, Codable {
    let id: UUID
    var reps: Int?
    var duration: Int?
    var distance: Double?
    var isCompleted: Bool
    let timestamp: Date
    
    init(reps: Int? = nil, duration: Int? = nil, distance: Double? = nil, isCompleted: Bool = false) {
        self.id = UUID()
        self.reps = reps
        self.duration = duration
        self.distance = distance
        self.isCompleted = isCompleted
        self.timestamp = Date()
    }
}

struct WorkoutExercise: Identifiable, Codable {
    let id: UUID
    let exerciseID: String
    var sets: [WorkoutSet]
    var targetSets: Int
    
    init(exerciseID: String, targetSets: Int = 0) {
        self.id = UUID()
        self.exerciseID = exerciseID
        self.sets = []
        self.targetSets = targetSets
    }
}

struct WorkoutTemplate: Identifiable, Codable {
    let id: UUID
    var name: String
    var exercises: [WorkoutExercise]
    let createdAt: Date
    
    init(name: String, exercises: [WorkoutExercise] = []) {
        self.id = UUID()
        self.name = name
        self.exercises = exercises
        self.createdAt = Date()
    }
}

struct ActiveWorkout: Identifiable, Codable {
    let id: UUID
    var name: String
    var exercises: [WorkoutExercise]
    let startTime: Date
    var endTime: Date?
    var isFromTemplate: Bool
    
    var isCompleted: Bool { endTime != nil }
    
    var duration: TimeInterval {
        guard let endTime = endTime else { return 0 }
        return endTime.timeIntervalSince(startTime)
    }
    
    var durationFormatted: String {
        let duration = self.duration
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    var totalSets: Int {
        exercises.flatMap { $0.sets }.count
    }
    
    var totalReps: Int {
        exercises.flatMap { $0.sets }.compactMap { $0.reps }.reduce(0, +)
    }
    
    var completedSets: Int {
        exercises.flatMap { $0.sets }.filter { $0.isCompleted }.count
    }
    
    var exerciseSummary: [String] {
        exercises.compactMap { exercise in
            if let exerciseData = WorkoutManager().getExercise(by: exercise.exerciseID) {
                let completedSets = exercise.sets.filter { $0.isCompleted }.count
                let totalSets = exercise.sets.count
                return "\(exerciseData.emoji) \(exerciseData.name): \(completedSets)/\(totalSets) sets"
            }
            return nil
        }
    }
    
    init(name: String, exercises: [WorkoutExercise] = [], isFromTemplate: Bool = false) {
        self.id = UUID()
        self.name = name
        self.exercises = exercises
        self.startTime = Date()
        self.endTime = nil
        self.isFromTemplate = isFromTemplate
    }
}

struct WorkoutSession: Identifiable {
    let id = UUID()
    let exerciseID: String
    var sets: [WorkoutSet]
    let startTime: Date
    
    init(exerciseID: String) {
        self.exerciseID = exerciseID
        self.sets = []
        self.startTime = Date()
    }
}

// MARK: - Workout Manager

class WorkoutManager: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var templates: [WorkoutTemplate] = []
    @Published var activeWorkout: ActiveWorkout?
    @Published var workoutHistory: [ActiveWorkout] = []
    @Published var currentSession: WorkoutSession?
    
    private let db = Firestore.firestore()
    
    init() {
        loadExercises()
        setupNotifications()
        setupAuthListener()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleResetAllData),
            name: .resetAllWorkoutData,
            object: nil
        )
    }
    
    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            DispatchQueue.main.async {
                if user != nil {
                    self?.loadTemplates()
                    self?.loadWorkoutHistory()
                } else {
                    self?.clearAllUserData()
                }
            }
        }
    }
    
    private func clearAllUserData() {
        print("🏋️ Clearing workout data for account switch")
        workoutHistory.removeAll()
        templates.removeAll()
        activeWorkout = nil
        currentSession = nil
    }
    
    @objc private func handleResetAllData() {
        resetAllData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func loadExercises() {
        exercises = [
            Exercise(id: "push_up", name: "Push-Up", type: .reps, category: "push", description: "Classic bodyweight pushing exercise", emoji: "🙌", difficulty: 2),
            Exercise(id: "knee_push_up", name: "Knee Push-Up", type: .reps, category: "push", description: "Modified push-up for beginners", emoji: "🦵", difficulty: 1),
            Exercise(id: "diamond_push_up", name: "Diamond Push-Up", type: .reps, category: "push", description: "Narrow hand push-up variation", emoji: "💎", difficulty: 4),
            Exercise(id: "plank", name: "Plank", type: .time, category: "core", description: "Isometric core strengthening", emoji: "🧱", difficulty: 2),
            Exercise(id: "hollow_hold", name: "Hollow Hold", type: .time, category: "core", description: "Core compression exercise", emoji: "🥚", difficulty: 3),
            Exercise(id: "squat", name: "Bodyweight Squat", type: .reps, category: "legs", description: "Basic lower body exercise", emoji: "🪑", difficulty: 1),
            Exercise(id: "wall_sit", name: "Wall Sit", type: .time, category: "legs", description: "Isometric leg exercise", emoji: "🧱", difficulty: 2),
            Exercise(id: "dead_hang", name: "Dead Hang", type: .time, category: "pull", description: "Hanging from pull-up bar", emoji: "🪢", difficulty: 2),
            Exercise(id: "pull_up", name: "Pull-Up", type: .reps, category: "pull", description: "Classic upper body pulling", emoji: "🆙", difficulty: 4),
            Exercise(id: "scapular_pulls", name: "Scapular Pulls", type: .reps, category: "pull", description: "Shoulder blade movement", emoji: "⬇️", difficulty: 2)
        ]
    }
    
    private func loadTemplates() {
        guard let user = Auth.auth().currentUser else {
            templates.removeAll()
            return
        }
        
        let templatesRef = db.collection("users").document(user.uid).collection("workouts").document("templates")
        
        templatesRef.getDocument { [weak self] document, error in
            if let error = error {
                print("❌ Error loading templates: \(error.localizedDescription)")
                return
            }
            
            DispatchQueue.main.async {
                if let document = document, document.exists,
                   let data = document.data(),
                   let templatesData = data["templates"] as? [[String: Any]] {
                    
                    let templates = templatesData.compactMap { templateData -> WorkoutTemplate? in
                        self?.decodeTemplateFromFirestore(templateData)
                    }
                    
                    self?.templates = templates
                    print("✅ Loaded \(templates.count) templates from Firebase")
                } else {
                    self?.templates.removeAll()
                }
            }
        }
    }
    
    private func decodeTemplateFromFirestore(_ data: [String: Any]) -> WorkoutTemplate? {
        guard let idString = data["id"] as? String,
              let templateId = UUID(uuidString: idString),
              let name = data["name"] as? String,
              let createdAtTimestamp = data["createdAt"] as? Timestamp,
              let exercisesData = data["exercises"] as? [[String: Any]] else {
            return nil
        }
        
        let exercises = exercisesData.compactMap { exerciseData -> WorkoutExercise? in
            guard let exerciseID = exerciseData["exerciseID"] as? String,
                  let targetSets = exerciseData["targetSets"] as? Int else {
                return nil
            }
            return WorkoutExercise(exerciseID: exerciseID, targetSets: targetSets)
        }
        
        return WorkoutTemplate(name: name, exercises: exercises)
    }
    
    private func saveTemplates() {
        if let data = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(data, forKey: "workoutTemplates")
        }
        
        guard let user = Auth.auth().currentUser else { return }
        
        let templatesRef = db.collection("users").document(user.uid).collection("workouts").document("templates")
        
        let templatesData = templates.map { template in
            return [
                "id": template.id.uuidString,
                "name": template.name,
                "exercises": template.exercises.map { exercise in
                    return [
                        "id": exercise.id.uuidString,
                        "exerciseID": exercise.exerciseID,
                        "targetSets": exercise.targetSets
                    ]
                },
                "createdAt": Timestamp(date: template.createdAt)
            ]
        }
        
        templatesRef.setData([
            "templates": templatesData,
            "lastUpdated": Timestamp()
        ]) { error in
            if let error = error {
                print("❌ Error saving templates: \(error.localizedDescription)")
            } else {
                print("✅ Templates saved to Firebase")
            }
        }
    }
    
    // MARK: - Firebase Workout History Management
    
    private func loadWorkoutHistory() {
        guard let user = Auth.auth().currentUser else {
            workoutHistory.removeAll()
            return
        }
        
        let workoutsRef = db.collection("users").document(user.uid).collection("workouts")
        
        workoutsRef
            .order(by: "startTime", descending: true)
            .limit(to: 100)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Error loading workout history: \(error.localizedDescription)")
                    return
                }
                
                DispatchQueue.main.async {
                    let workouts = snapshot?.documents.compactMap { doc -> ActiveWorkout? in
                        self?.decodeWorkoutFromFirestore(doc.data(), id: doc.documentID)
                    } ?? []
                    
                    self?.workoutHistory = workouts
                    print("✅ Loaded \(workouts.count) workouts from Firebase")
                }
            }
    }
    
    // MARK: - Enhanced Firebase Save (Using Working Pattern)
    private func saveWorkoutToFirebase(_ workout: ActiveWorkout) {
        guard let user = Auth.auth().currentUser else {
            print("❌ Cannot save workout: No authenticated user")
            return
        }
        
        print("🔑 Saving workout for user ID: \(user.uid)")
        print("🏋️ Workout ID: \(workout.id.uuidString)")
        
        let workoutRef = db.collection("users").document(user.uid).collection("workouts").document(workout.id.uuidString)
        
        // Create comprehensive workout data structure using the working pattern
        let workoutData: [String: Any] = [
            "id": workout.id.uuidString,
            "name": workout.name,
            "startTime": Timestamp(date: workout.startTime),
            "endTime": workout.endTime != nil ? Timestamp(date: workout.endTime!) : NSNull(),
            "isFromTemplate": workout.isFromTemplate,
            "durationSeconds": workout.duration,
            "durationFormatted": workout.durationFormatted,
            "totalSets": workout.totalSets,
            "completedSets": workout.completedSets,
            "totalReps": workout.totalReps,
            "exercises": workout.exercises.map { exercise in
                let exerciseData = self.getExercise(by: exercise.exerciseID)
                return [
                    "id": exercise.id.uuidString,
                    "exerciseID": exercise.exerciseID,
                    "exerciseName": exerciseData?.name ?? "Unknown Exercise",
                    "exerciseEmoji": exerciseData?.emoji ?? "💪",
                    "exerciseCategory": exerciseData?.category ?? "general",
                    "exerciseType": exerciseData?.type.rawValue ?? "reps",
                    "targetSets": exercise.targetSets,
                    "actualSets": exercise.sets.count,
                    "completedSets": exercise.sets.filter { $0.isCompleted }.count,
                    "sets": exercise.sets.map { set in
                        return [
                            "id": set.id.uuidString,
                            "reps": set.reps ?? NSNull(),
                            "duration": set.duration ?? NSNull(),
                            "distance": set.distance ?? NSNull(),
                            "isCompleted": set.isCompleted,
                            "timestamp": Timestamp(date: set.timestamp),
                            "readableValue": self.formatSetValue(set: set, exerciseType: exerciseData?.type ?? .reps)
                        ]
                    }
                ]
            },
            "summary": [
                "duration": workout.durationFormatted,
                "exerciseCount": workout.exercises.count,
                "exerciseNames": workout.exercises.compactMap { exercise in
                    self.getExercise(by: exercise.exerciseID)?.name
                },
                "totalVolume": workout.totalReps > 0 ? "\(workout.totalReps) reps" : "Time-based workout"
            ],
            "createdAt": Timestamp(),
            "lastUpdated": Timestamp()
        ]
        
        // Use the exact working Firebase pattern
        workoutRef.setData(workoutData) { error in
            if let error = error {
                print("❌ Error saving workout: \(error.localizedDescription)")
            } else {
                print("✅ Workout saved to Firebase")
                self.updateStreakData(workoutDate: workout.startTime)
            }
        }
    }
    
    private func updateStreakData(workoutDate: Date) {
        guard let user = Auth.auth().currentUser else { return }
        
        let streakRef = db.collection("users").document(user.uid).collection("quests").document("streaks")
        let dateString = DateFormatter.workoutDateFormatter.string(from: workoutDate)
        
        streakRef.getDocument { document, error in
            var workoutDates: [String] = []
            var currentStreak = 1
            var longestStreak = 1
            
            if let doc = document, doc.exists,
               let data = doc.data() {
                workoutDates = data["workoutDates"] as? [String] ?? []
                currentStreak = data["currentStreak"] as? Int ?? 1
                longestStreak = data["longestStreak"] as? Int ?? 1
            }
            
            if !workoutDates.contains(dateString) {
                workoutDates.append(dateString)
                let sortedDates = workoutDates.compactMap { DateFormatter.workoutDateFormatter.date(from: $0) }.sorted()
                currentStreak = self.calculateCurrentStreak(from: sortedDates)
                longestStreak = max(longestStreak, currentStreak)
            }
            
            let streakData: [String: Any] = [
                "workoutDates": workoutDates,
                "currentStreak": currentStreak,
                "longestStreak": longestStreak,
                "lastWorkoutDate": Timestamp(date: workoutDate),
                "lastUpdated": Timestamp()
            ]
            
            streakRef.setData(streakData) { error in
                if let error = error {
                    print("❌ Error saving streak data: \(error.localizedDescription)")
                } else {
                    print("✅ Streak data updated: \(currentStreak) day streak")
                }
            }
        }
    }
    
    private func calculateCurrentStreak(from dates: [Date]) -> Int {
        guard !dates.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var currentStreak = 0
        
        for i in stride(from: dates.count - 1, through: 0, by: -1) {
            let date = calendar.startOfDay(for: dates[i])
            let daysDifference = calendar.dateComponents([.day], from: date, to: today).day ?? 0
            
            if daysDifference == currentStreak {
                currentStreak += 1
            } else {
                break
            }
        }
        
        return currentStreak
    }
    
    private func decodeWorkoutFromFirestore(_ data: [String: Any], id: String) -> ActiveWorkout? {
        guard let idString = data["id"] as? String,
              let workoutId = UUID(uuidString: idString),
              let name = data["name"] as? String,
              let startTimeStamp = data["startTime"] as? Timestamp,
              let isFromTemplate = data["isFromTemplate"] as? Bool,
              let exercisesData = data["exercises"] as? [[String: Any]] else {
            return nil
        }
        
        // Create exercises array first
        let exercises = exercisesData.compactMap { exerciseData -> WorkoutExercise? in
            guard let exerciseID = exerciseData["exerciseID"] as? String,
                  let targetSets = exerciseData["targetSets"] as? Int,
                  let setsData = exerciseData["sets"] as? [[String: Any]] else {
                return nil
            }
            
            var workoutExercise = WorkoutExercise(exerciseID: exerciseID, targetSets: targetSets)
            
            let sets = setsData.compactMap { setData -> WorkoutSet? in
                let reps = setData["reps"] as? Int
                let duration = setData["duration"] as? Int
                let distance = setData["distance"] as? Double
                let isCompleted = setData["isCompleted"] as? Bool ?? false
                
                return WorkoutSet(reps: reps, duration: duration, distance: distance, isCompleted: isCompleted)
            }
            
            workoutExercise.sets = sets
            return workoutExercise
        }
        
        // Create workout with decoded exercises
        var workout = ActiveWorkout(name: name, exercises: exercises, isFromTemplate: isFromTemplate)
        workout.endTime = (data["endTime"] as? Timestamp)?.dateValue()
        
        return workout
    }
    
    private func formatSetValue(set: WorkoutSet, exerciseType: ExerciseType) -> String {
        switch exerciseType {
        case .reps:
            return "\(set.reps ?? 0) reps"
        case .time:
            let seconds = set.duration ?? 0
            if seconds >= 60 {
                return "\(seconds / 60)m \(seconds % 60)s"
            } else {
                return "\(seconds)s"
            }
        case .distance:
            return String(format: "%.1f km", set.distance ?? 0.0)
        }
    }
    
    func getExercise(by id: String) -> Exercise? {
        return exercises.first { $0.id == id }
    }
    
    func getExercises(by category: String) -> [Exercise] {
        return exercises.filter { $0.category == category }
    }
    
    // MARK: - Workout Management
    
    func startBlankWorkout() {
        let workout = ActiveWorkout(name: "Workout \(Date().formatted(date: .omitted, time: .shortened))")
        activeWorkout = workout
    }
    
    func startWorkoutFromTemplate(_ template: WorkoutTemplate) {
        let workoutExercises = template.exercises.map { templateExercise in
            var workoutExercise = WorkoutExercise(exerciseID: templateExercise.exerciseID, targetSets: templateExercise.targetSets)
            for _ in 0..<templateExercise.targetSets {
                if let exercise = getExercise(by: templateExercise.exerciseID) {
                    switch exercise.type {
                    case .reps:
                        workoutExercise.sets.append(WorkoutSet(reps: 0))
                    case .time:
                        workoutExercise.sets.append(WorkoutSet(duration: 0))
                    case .distance:
                        workoutExercise.sets.append(WorkoutSet(distance: 0))
                    }
                }
            }
            return workoutExercise
        }
        
        let workout = ActiveWorkout(name: template.name, exercises: workoutExercises, isFromTemplate: true)
        activeWorkout = workout
    }
    
    func addExerciseToWorkout(_ exerciseID: String) {
        guard var workout = activeWorkout else { return }
        
        if !workout.exercises.contains(where: { $0.exerciseID == exerciseID }) {
            let workoutExercise = WorkoutExercise(exerciseID: exerciseID)
            workout.exercises.append(workoutExercise)
            activeWorkout = workout
        }
    }
    
    func addSetToExercise(exerciseIndex: Int) {
        guard var workout = activeWorkout else { return }
        guard exerciseIndex < workout.exercises.count else { return }
        
        let exerciseID = workout.exercises[exerciseIndex].exerciseID
        guard let exercise = getExercise(by: exerciseID) else { return }
        
        var newSet: WorkoutSet
        switch exercise.type {
        case .reps:
            newSet = WorkoutSet(reps: nil, isCompleted: false)
        case .time:
            newSet = WorkoutSet(duration: nil, isCompleted: false)
        case .distance:
            newSet = WorkoutSet(distance: nil, isCompleted: false)
        }
        
        workout.exercises[exerciseIndex].sets.append(newSet)
        activeWorkout = workout
    }
    
    func updateSet(exerciseIndex: Int, setIndex: Int, reps: Int? = nil, duration: Int? = nil, distance: Double? = nil) {
        guard var workout = activeWorkout else { return }
        guard exerciseIndex < workout.exercises.count else { return }
        guard setIndex < workout.exercises[exerciseIndex].sets.count else { return }
        
        var set = workout.exercises[exerciseIndex].sets[setIndex]
        
        if let reps = reps {
            set.reps = reps
        }
        if let duration = duration {
            set.duration = duration
        }
        if let distance = distance {
            set.distance = distance
        }
        
        let exerciseID = workout.exercises[exerciseIndex].exerciseID
        if let exercise = getExercise(by: exerciseID) {
            switch exercise.type {
            case .reps:
                set.isCompleted = (set.reps ?? 0) > 0
            case .time:
                set.isCompleted = (set.duration ?? 0) > 0
            case .distance:
                set.isCompleted = (set.distance ?? 0.0) > 0.0
            }
        } else {
            set.isCompleted = (set.reps ?? 0) > 0 || (set.duration ?? 0) > 0 || (set.distance ?? 0.0) > 0.0
        }
        
        workout.exercises[exerciseIndex].sets[setIndex] = set
        activeWorkout = workout
        
        print("📝 Updated set \(setIndex + 1): reps=\(set.reps?.description ?? "nil"), duration=\(set.duration?.description ?? "nil"), distance=\(set.distance?.description ?? "nil"), completed=\(set.isCompleted)")
    }
    
    func removeSet(exerciseIndex: Int, setIndex: Int) {
        guard var workout = activeWorkout else { return }
        guard exerciseIndex < workout.exercises.count else { return }
        guard setIndex < workout.exercises[exerciseIndex].sets.count else { return }
        
        workout.exercises[exerciseIndex].sets.remove(at: setIndex)
        activeWorkout = workout
    }
    
    func finishWorkout() {
        guard var workout = activeWorkout else { 
            print("❌ No active workout to finish")
            return 
        }
        
        print("🏋️ Finishing workout: \(workout.name) with \(workout.exercises.count) exercises")
        
        workout.endTime = Date()
        workoutHistory.append(workout)
        
        print("💾 Saving workout to Firebase...")
        saveWorkoutToFirebase(workout)
        
        StreakManager.shared.recordWorkoutCompletion(date: workout.startTime)
        QuestManager.shared.updateQuestProgress(from: workout)
        
        activeWorkout = nil
        print("✅ Workout finished and cleared from active state")
    }
    
    func cancelWorkout() {
        activeWorkout = nil
        currentSession = nil
    }
    
    // MARK: - Template Management
    
    func createTemplate(name: String, exercises: [WorkoutExercise]) {
        let template = WorkoutTemplate(name: name, exercises: exercises)
        templates.append(template)
        saveTemplates()
    }
    
    func deleteTemplate(_ template: WorkoutTemplate) {
        templates.removeAll { $0.id == template.id }
        saveTemplates()
    }
    
    // MARK: - Statistics
    
    func getTodaysStats() -> (workouts: Int, sets: Int, totalReps: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        let todaysWorkouts = workoutHistory.filter {
            Calendar.current.isDate($0.startTime, inSameDayAs: today)
        }
        
        let totalSets = todaysWorkouts.flatMap { $0.exercises }.flatMap { $0.sets }.count
        let totalReps = todaysWorkouts.flatMap { $0.exercises }.flatMap { $0.sets }.compactMap { $0.reps }.reduce(0, +)
        
        return (workouts: todaysWorkouts.count, sets: totalSets, totalReps: totalReps)
    }
    
    // MARK: - Reset Functionality
    
    func resetAllData() {
        print("🏋️ Starting WorkoutManager reset...")
        
        DispatchQueue.main.async {
            self.workoutHistory.removeAll()
            self.templates.removeAll()
            self.activeWorkout = nil
            self.currentSession = nil
            
            print("🏋️ In-memory workout data cleared, now clearing Firebase...")
        }
        
        clearFirebaseWorkoutData()
        print("✅ WorkoutManager reset complete")
    }
    
    private func clearFirebaseWorkoutData() {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)
        
        let collections = ["workouts"]
        
        collections.forEach { collectionName in
            userRef.collection(collectionName).getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error getting \(collectionName) documents: \(error.localizedDescription)")
                    return
                }
                
                let batch = db.batch()
                snapshot?.documents.forEach { document in
                    batch.deleteDocument(document.reference)
                }
                
                batch.commit { error in
                    if let error = error {
                        print("❌ Error deleting \(collectionName): \(error.localizedDescription)")
                    } else {
                        print("✅ \(collectionName) collection cleared from Firebase")
                    }
                }
            }
        }
    }
}

// MARK: - REQUIREMENT 1: Main Workout View (Start Blank or Create Template)

struct WorkoutTrackerView: View {
    @ObservedObject var workoutManager: WorkoutManager
    @StateObject private var colorManager: AppColorManager
    
    init(workoutManager: WorkoutManager) {
        self.workoutManager = workoutManager
        self._colorManager = StateObject(wrappedValue: AppColorManager(useElectricTheme: true))
    }
    
    var body: some View {
        NavigationView {
            Group {
                if let activeWorkout = workoutManager.activeWorkout {
                    ActiveWorkoutView(workoutManager: workoutManager, workout: activeWorkout)
                } else {
                    WorkoutStartView(workoutManager: workoutManager)
                }
            }
        }
        .sheet(item: $workoutManager.currentSession) { session in
            WorkoutSessionView(workoutManager: workoutManager, session: session)
        }
    }
}

// MARK: - Workout Start View (Blank Workout or Create Template)

struct WorkoutStartView: View {
    @ObservedObject var workoutManager: WorkoutManager
    @StateObject private var colorManager: AppColorManager
    @State private var showingTemplateCreator = false
    
    init(workoutManager: WorkoutManager) {
        self.workoutManager = workoutManager
        self._colorManager = StateObject(wrappedValue: AppColorManager(useElectricTheme: true))
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 20)
            
            // Today's Stats
            todaysStatsCard
            
            // Main Action Buttons
            VStack(spacing: 20) {
                Button(action: {
                    workoutManager.startBlankWorkout()
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Start Blank Workout")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(colorManager.theme.buttonGradient)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
                
                Button(action: {
                    showingTemplateCreator = true
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: "doc.badge.plus")
                            .font(.title2)
                        Text("Create Template")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
            }
            .padding(.horizontal, 24)
            
            // Templates Section
            if !workoutManager.templates.isEmpty {
                templatesSection
            } else {
                VStack(spacing: 16) {
                    Text("No Templates Yet")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("Create your first workout template to get started faster")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.vertical, 32)
            }
            
            Spacer()
        }
        .sheet(isPresented: $showingTemplateCreator) {
            TemplateCreatorView(workoutManager: workoutManager)
        }
    }
    
    private var todaysStatsCard: some View {
        let stats = workoutManager.getTodaysStats()
        
        return VStack(spacing: 16) {
            Text("Today's Progress")
                .font(.title2)
                .fontWeight(.semibold)
            
            HStack(spacing: 40) {
                VStack(spacing: 8) {
                    Text("\(stats.workouts)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(colorManager.theme.primary)
                    Text("Workouts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 8) {
                    Text("\(stats.sets)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(colorManager.theme.tertiary)
                    Text("Sets")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 8) {
                    Text("\(stats.totalReps)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(colorManager.theme.accent)
                    Text("Reps")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(24)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(20)
        .padding(.horizontal, 24)
    }
    
    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Workout Templates")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal, 24)
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(workoutManager.templates) { template in
                        TemplateRow(template: template, workoutManager: workoutManager) {
                            workoutManager.startWorkoutFromTemplate(template)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(maxHeight: 200)
        }
    }
}

// MARK: - Template Row

struct TemplateRow: View {
    let template: WorkoutTemplate
    let workoutManager: WorkoutManager
    let onStart: () -> Void
    @StateObject private var colorManager: AppColorManager
    
    init(template: WorkoutTemplate, workoutManager: WorkoutManager, onStart: @escaping () -> Void) {
        self.template = template
        self.workoutManager = workoutManager
        self.onStart = onStart
        self._colorManager = StateObject(wrappedValue: AppColorManager(useElectricTheme: true))
    }
    
    var body: some View {
        Button(action: onStart) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(template.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("\(template.exercises.count) exercises")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        ForEach(template.exercises.prefix(3), id: \.id) { exercise in
                            if let exerciseData = workoutManager.getExercise(by: exercise.exerciseID) {
                                Text(exerciseData.emoji)
                                    .font(.caption)
                            }
                        }
                        if template.exercises.count > 3 {
                            Text("+\(template.exercises.count - 3)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(colorManager.theme.primary)
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Active Workout View

struct ActiveWorkoutView: View {
    @ObservedObject var workoutManager: WorkoutManager
    let workout: ActiveWorkout
    @StateObject private var colorManager: AppColorManager
    @State private var showingExercisePicker = false
    
    init(workoutManager: WorkoutManager, workout: ActiveWorkout) {
        self.workoutManager = workoutManager
        self.workout = workout
        self._colorManager = StateObject(wrappedValue: AppColorManager(useElectricTheme: true))
    }
    
    @State private var workoutDuration: TimeInterval = 0
    @State private var workoutTimer: Timer?
    
    var body: some View {
        VStack(spacing: 0) {
            workoutHeader
            
            if workout.exercises.isEmpty {
                emptyWorkoutView
            } else {
                exercisesList
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    workoutManager.cancelWorkout()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Finish") {
                    workoutManager.finishWorkout()
                }
                .disabled(workout.exercises.isEmpty)
            }
        }
        .onAppear {
            startWorkoutTimer()
        }
        .onDisappear {
            stopWorkoutTimer()
        }
    }
    
    private var workoutHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(workout.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(formatWorkoutDuration(workoutDuration))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(colorManager.theme.primary)
                    
                    Text("Started \(workout.startTime, style: .time)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !workout.exercises.isEmpty {
                    Button("Add Exercise") {
                        showingExercisePicker = true
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(colorManager.theme.primaryGradient)
                    .clipShape(Capsule())
                }
            }
            
            HStack(spacing: 30) {
                VStack {
                    Text("\(workout.exercises.count)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(colorManager.theme.primary)
                    Text("Exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(totalSets)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(colorManager.theme.tertiary)
                    Text("Sets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(totalReps)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(colorManager.theme.accent)
                    Text("Reps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView(workoutManager: workoutManager)
        }
    }
    
    private var emptyWorkoutView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 32) {
                Button(action: {
                    showingExercisePicker = true
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        colorManager.theme.primary.opacity(0.1),
                                        colorManager.theme.tertiary.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(colorManager.theme.primary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(spacing: 12) {
                    Text("Ready to start?")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Add your first exercise to begin this workout")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Text("Tap the plus button to add your first exercise")
                    .font(.callout)
                    .foregroundColor(Color.secondary.opacity(0.7))
                    .italic()
            }
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            colorManager.subtleBackgroundGradient
        )
    }
    
    private var exercisesList: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { exerciseIndex, workoutExercise in
                    if let exercise = workoutManager.getExercise(by: workoutExercise.exerciseID) {
                        ExerciseWorkoutCard(
                            exercise: exercise,
                            workoutExercise: workoutExercise,
                            exerciseIndex: exerciseIndex,
                            workoutManager: workoutManager
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .onTapGesture {
            // Focus state will handle keyboard dismissal
        }
    }
    
    private var totalSets: Int {
        workout.exercises.reduce(0) { $0 + $1.sets.count }
    }
    
    private var totalReps: Int {
        workout.exercises.flatMap { $0.sets }.compactMap { $0.reps }.reduce(0, +)
    }
    
    private func startWorkoutTimer() {
        workoutDuration = Date().timeIntervalSince(workout.startTime)
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            workoutDuration = Date().timeIntervalSince(workout.startTime)
        }
    }
    
    private func stopWorkoutTimer() {
        workoutTimer?.invalidate()
        workoutTimer = nil
    }
    
    private func formatWorkoutDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Exercise Workout Card

struct ExerciseWorkoutCard: View {
    let exercise: Exercise
    let workoutExercise: WorkoutExercise
    let exerciseIndex: Int
    @ObservedObject var workoutManager: WorkoutManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Text(exercise.emoji)
                    .font(.system(size: 28))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(exercise.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("\(workoutExercise.sets.count) sets")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Add Set") {
                    workoutManager.addSetToExercise(exerciseIndex: exerciseIndex)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            if !workoutExercise.sets.isEmpty {
                VStack(spacing: 12) {
                    ForEach(Array(workoutExercise.sets.enumerated()), id: \.element.id) { setIndex, set in
                        SetRow(
                            setNumber: setIndex + 1,
                            set: set,
                            exercise: exercise,
                            onUpdate: { reps, duration, distance in
                                workoutManager.updateSet(
                                    exerciseIndex: exerciseIndex,
                                    setIndex: setIndex,
                                    reps: reps,
                                    duration: duration,
                                    distance: distance
                                )
                            },
                            onDelete: {
                                workoutManager.removeSet(exerciseIndex: exerciseIndex, setIndex: setIndex)
                            }
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Set Row

struct SetRow: View {
    let setNumber: Int
    let set: WorkoutSet
    let exercise: Exercise
    let onUpdate: (Int?, Int?, Double?) -> Void
    let onDelete: () -> Void
    
    @State private var repsInput: String = ""
    @State private var durationInput: String = ""
    @FocusState private var isInputFocused: Bool
    
    @State private var isRestTimerActive = false
    @State private var restDuration = 0
    @State private var restTimeRemaining = 0
    @State private var restTimer: Timer?
    @State private var showingRestPicker = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Text("Set \(setNumber)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(width: 70, alignment: .leading)
                
                switch exercise.type {
                case .reps:
                    HStack(spacing: 8) {
                        TextField("0", text: $repsInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 80)
                            .focused($isInputFocused)
                            .onAppear {
                                repsInput = set.reps != nil && set.reps! > 0 ? "\(set.reps!)" : ""
                            }
                            .onChange(of: repsInput) { _, newValue in
                                let reps = Int(newValue) ?? 0
                                onUpdate(reps > 0 ? reps : nil, nil, nil)
                            }
                        
                        Text("reps")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                case .time:
                    HStack(spacing: 8) {
                        TextField("0", text: $durationInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 80)
                            .focused($isInputFocused)
                            .onAppear {
                                durationInput = set.duration != nil && set.duration! > 0 ? "\(set.duration!)" : ""
                            }
                            .onChange(of: durationInput) { _, newValue in
                                let duration = Int(newValue) ?? 0
                                onUpdate(nil, duration > 0 ? duration : nil, nil)
                            }
                        
                        Text("sec")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                case .distance:
                    HStack(spacing: 8) {
                        TextField("0", text: $durationInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                            .focused($isInputFocused)
                            .onAppear {
                                durationInput = set.distance != nil && set.distance! > 0 ? "\(set.distance!)" : ""
                            }
                            .onChange(of: durationInput) { _, newValue in
                                let distance = Double(newValue) ?? 0
                                onUpdate(nil, nil, distance > 0 ? distance : nil)
                            }
                        
                        Text("m")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if set.isCompleted {
                    Button(action: {
                        if isRestTimerActive {
                            stopRestTimer()
                        } else if restDuration > 0 {
                            startRestTimer()
                        }
                    }) {
                        ZStack {
                            if isRestTimerActive {
                                Circle()
                                    .stroke(Color.orange, lineWidth: 3)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Text("\(restTimeRemaining)")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.orange)
                                    )
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundColor(.red)
                }
            }
            
            if set.isCompleted {
                HStack {
                    Text("Rest:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("\(restDuration == 0 ? "None" : "\(restDuration)s")") {
                        showingRestPicker = true
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(8)
                    .foregroundColor(restDuration == 0 ? .secondary : .orange)
                    
                    Spacer()
                }
                .actionSheet(isPresented: $showingRestPicker) {
                    ActionSheet(
                        title: Text("Rest Timer"),
                        message: Text("Select rest duration"),
                        buttons: [
                            .default(Text("No Rest")) { restDuration = 0 },
                            .default(Text("30 seconds")) { restDuration = 30 },
                            .default(Text("60 seconds")) { restDuration = 60 },
                            .default(Text("90 seconds")) { restDuration = 90 },
                            .default(Text("2 minutes")) { restDuration = 120 },
                            .default(Text("3 minutes")) { restDuration = 180 },
                            .cancel()
                        ]
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(12)
        .onTapGesture {
            isInputFocused = false
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isInputFocused = false
                }
            }
        }
    }
    
    private func startRestTimer() {
        isRestTimerActive = true
        restTimeRemaining = restDuration
        
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if restTimeRemaining > 0 {
                restTimeRemaining -= 1
            } else {
                stopRestTimer()
                if #available(iOS 17.0, *) {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
            }
        }
    }
    
    private func stopRestTimer() {
        isRestTimerActive = false
        restTimer?.invalidate()
        restTimer = nil
    }
}

// MARK: - Exercise Picker

struct ExercisePickerView: View {
    @ObservedObject var workoutManager: WorkoutManager
    @StateObject private var colorManager: AppColorManager
    @Environment(\.presentationMode) var presentationMode
    
    init(workoutManager: WorkoutManager) {
        self.workoutManager = workoutManager
        self._colorManager = StateObject(wrappedValue: AppColorManager(useElectricTheme: true))
    }
    @State private var selectedCategory = "all"
    @State private var selectedExercise: Exercise?
    @State private var showingRestSelection = false
    
    private let categories = [
        ("all", "All", "🏋️"),
        ("push", "Push", "🙌"),
        ("pull", "Pull", "🆙"),
        ("core", "Core", "🧱"),
        ("legs", "Legs", "🦿")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                categorySelector
                exerciseList
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .actionSheet(isPresented: $showingRestSelection) {
                ActionSheet(
                    title: Text("Set Rest Timer"),
                    message: Text("Choose rest duration for \(selectedExercise?.name ?? "this exercise")"),
                    buttons: [
                        .default(Text("No Rest Timer")) {
                            addExerciseWithRestTimer(0)
                        },
                        .default(Text("30 seconds")) {
                            addExerciseWithRestTimer(30)
                        },
                        .default(Text("60 seconds")) {
                            addExerciseWithRestTimer(60)
                        },
                        .default(Text("90 seconds")) {
                            addExerciseWithRestTimer(90)
                        },
                        .default(Text("2 minutes")) {
                            addExerciseWithRestTimer(120)
                        },
                        .default(Text("3 minutes")) {
                            addExerciseWithRestTimer(180)
                        },
                        .cancel()
                    ]
                )
            }
        }
    }
    
    private func addExerciseWithRestTimer(_ restDuration: Int) {
        guard let exercise = selectedExercise else { return }
        workoutManager.addExerciseToWorkout(exercise.id)
        presentationMode.wrappedValue.dismiss()
    }
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.0) { category in
                    Button(action: { selectedCategory = category.0 }) {
                        VStack(spacing: 6) {
                            Text(category.2)
                                .font(.title3)
                            Text(category.1)
                                .font(.caption)
                                .fontWeight(selectedCategory == category.0 ? .semibold : .medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedCategory == category.0 ? 
                                      AnyShapeStyle(colorManager.theme.primaryGradient)
                                      : AnyShapeStyle(Color(UIColor.secondarySystemBackground)))
                        )
                        .foregroundColor(selectedCategory == category.0 ? .white : .primary)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
    }
    
    private var exerciseList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredExercises) { exercise in
                    Button(action: {
                        selectedExercise = exercise
                        showingRestSelection = true
                    }) {
                        HStack(spacing: 16) {
                            Text(exercise.emoji)
                                .font(.system(size: 28))
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(exercise.name)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text(exercise.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(exercise.type.rawValue.capitalized)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(colorManager.theme.primary.opacity(0.2))
                                    .foregroundColor(colorManager.theme.primary)
                                    .clipShape(Capsule())
                            }
                            
                            Spacer()
                            
                            Image(systemName: "plus.circle")
                                .font(.title2)
                                .foregroundColor(colorManager.theme.primary)
                        }
                        .padding(16)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var filteredExercises: [Exercise] {
        if selectedCategory == "all" {
            return workoutManager.exercises
        } else {
            return workoutManager.getExercises(by: selectedCategory)
        }
    }
}

// MARK: - Template Creator

struct TemplateCreatorView: View {
    @ObservedObject var workoutManager: WorkoutManager
    @StateObject private var colorManager: AppColorManager
    @Environment(\.presentationMode) var presentationMode
    
    init(workoutManager: WorkoutManager) {
        self.workoutManager = workoutManager
        self._colorManager = StateObject(wrappedValue: AppColorManager(useElectricTheme: true))
    }
    
    @State private var templateName = ""
    @State private var selectedExercises: [WorkoutExercise] = []
    @State private var showingExercisePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Template Name")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    TextField("Enter template name", text: $templateName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Exercises")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button("Add Exercise") {
                            showingExercisePicker = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding(.horizontal, 20)
                    
                    if selectedExercises.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "plus.circle.dashed")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            
                            Text("No exercises added")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(selectedExercises.enumerated()), id: \.element.id) { index, workoutExercise in
                                    if let exercise = workoutManager.getExercise(by: workoutExercise.exerciseID) {
                                        TemplateExerciseRow(
                                            exercise: exercise,
                                            targetSets: workoutExercise.targetSets,
                                            onUpdateSets: { newTargetSets in
                                                selectedExercises[index].targetSets = newTargetSets
                                            },
                                            onRemove: {
                                                selectedExercises.remove(at: index)
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                
                Spacer()
                
                Button("Create Template") {
                    workoutManager.createTemplate(name: templateName, exercises: selectedExercises)
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(templateName.isEmpty || selectedExercises.isEmpty)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Create Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                TemplateExercisePickerView(
                    workoutManager: workoutManager,
                    selectedExercises: $selectedExercises
                )
            }
        }
    }
}

// MARK: - Template Exercise Row

struct TemplateExerciseRow: View {
    let exercise: Exercise
    let targetSets: Int
    let onUpdateSets: (Int) -> Void
    let onRemove: () -> Void
    @StateObject private var colorManager: AppColorManager
    
    init(exercise: Exercise, targetSets: Int, onUpdateSets: @escaping (Int) -> Void, onRemove: @escaping () -> Void) {
        self.exercise = exercise
        self.targetSets = targetSets
        self.onUpdateSets = onUpdateSets
        self.onRemove = onRemove
        self._colorManager = StateObject(wrappedValue: AppColorManager(useElectricTheme: true))
    }
    
    @State private var setsInput: String = ""
    
    var body: some View {
        HStack {
            Text(exercise.emoji)
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(exercise.type.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(colorManager.theme.primary.opacity(0.2))
                    .foregroundColor(colorManager.theme.primary)
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Text("Sets:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("0", text: $setsInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .frame(width: 60)
                    .onAppear {
                        setsInput = targetSets > 0 ? "\(targetSets)" : ""
                    }
                    .onChange(of: setsInput) { _, newValue in
                        let sets = Int(newValue) ?? 0
                        onUpdateSets(sets)
                    }
                
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Template Exercise Picker

struct TemplateExercisePickerView: View {
    @ObservedObject var workoutManager: WorkoutManager
    @Binding var selectedExercises: [WorkoutExercise]
    @StateObject private var colorManager: AppColorManager
    @Environment(\.presentationMode) var presentationMode
    
    init(workoutManager: WorkoutManager, selectedExercises: Binding<[WorkoutExercise]>) {
        self.workoutManager = workoutManager
        self._selectedExercises = selectedExercises
        self._colorManager = StateObject(wrappedValue: AppColorManager(useElectricTheme: true))
    }
    @State private var selectedCategory = "all"
    
    private let categories = [
        ("all", "All", "🏋️"),
        ("push", "Push", "🙌"),
        ("pull", "Pull", "🆙"),
        ("core", "Core", "🧱"),
        ("legs", "Legs", "🦿")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.0) { category in
                            Button(action: { selectedCategory = category.0 }) {
                                VStack(spacing: 6) {
                                    Text(category.2)
                                        .font(.title3)
                                    Text(category.1)
                                        .font(.caption)
                                        .fontWeight(selectedCategory == category.0 ? .semibold : .medium)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedCategory == category.0 ? 
                                              AnyShapeStyle(colorManager.theme.primaryGradient)
                                              : AnyShapeStyle(Color(UIColor.secondarySystemBackground)))
                                )
                                .foregroundColor(selectedCategory == category.0 ? .white : .primary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredExercises) { exercise in
                            let isSelected = selectedExercises.contains { $0.exerciseID == exercise.id }
                            
                            Button(action: {
                                if isSelected {
                                    selectedExercises.removeAll { $0.exerciseID == exercise.id }
                                } else {
                                    selectedExercises.append(WorkoutExercise(exerciseID: exercise.id, targetSets: 3))
                                }
                            }) {
                                HStack(spacing: 16) {
                                    Text(exercise.emoji)
                                        .font(.system(size: 28))
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(exercise.name)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        
                                        Text(exercise.description)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        Text(exercise.type.rawValue.capitalized)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(colorManager.theme.primary.opacity(0.2))
                                            .foregroundColor(colorManager.theme.primary)
                                            .clipShape(Capsule())
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                                        .font(.title2)
                                        .foregroundColor(isSelected ? colorManager.theme.success : colorManager.theme.primary)
                                }
                                .padding(16)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isSelected ? colorManager.theme.success : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle("Select Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(selectedExercises.isEmpty)
                }
            }
        }
    }
    
    private var filteredExercises: [Exercise] {
        if selectedCategory == "all" {
            return workoutManager.exercises
        } else {
            return workoutManager.getExercises(by: selectedCategory)
        }
    }
}

// MARK: - Simple Workout Session View (for backward compatibility)

struct WorkoutSessionView: View {
    @ObservedObject var workoutManager: WorkoutManager
    let session: WorkoutSession
    @Environment(\.presentationMode) var presentationMode
    @State private var repsInput: String = ""
    @State private var durationInput: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if let exercise = workoutManager.getExercise(by: session.exerciseID) {
                    VStack(spacing: 12) {
                        Text(exercise.emoji)
                            .font(.system(size: 48))
                        
                        Text(exercise.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Started at \(session.startTime, style: .time)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Completed Sets")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if session.sets.isEmpty {
                            Text("No sets completed yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 20)
                        } else {
                            ForEach(Array(session.sets.enumerated()), id: \.offset) { index, set in
                                HStack {
                                    Text("Set \(index + 1)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .frame(width: 60, alignment: .leading)
                                    
                                    Text(setDescription(set))
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Button(action: {
                                        // Remove last set functionality
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(UIColor.tertiarySystemBackground))
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Add New Set")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if exercise.type == .reps {
                            HStack {
                                Text("Reps:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                TextField("Enter reps", text: $repsInput)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                                    .frame(width: 100)
                            }
                            
                            Button("Add Set") {
                                if let reps = Int(repsInput), reps > 0 {
                                    // Add set functionality
                                    repsInput = ""
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(repsInput.isEmpty || Int(repsInput) == nil)
                        } else if exercise.type == .time {
                            HStack {
                                Text("Duration (seconds):")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                TextField("Enter seconds", text: $durationInput)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                                    .frame(width: 100)
                            }
                            
                            Button("Add Set") {
                                if let duration = Int(durationInput), duration > 0 {
                                    // Add set functionality
                                    durationInput = ""
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(durationInput.isEmpty || Int(durationInput) == nil)
                        }
                    }
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button("Finish Workout") {
                        // End workout functionality
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(session.sets.isEmpty)
                    
                    Button("Cancel Workout") {
                        workoutManager.cancelWorkout()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .padding(20)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        workoutManager.cancelWorkout()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func setDescription(_ set: WorkoutSet) -> String {
        if let reps = set.reps {
            return "\(reps) reps"
        } else if let duration = set.duration {
            return "\(duration) seconds"
        } else if let distance = set.distance {
            return "\(distance) meters"
        }
        return "Unknown"
    }
}