//
//  WorkoutTracker.swift
//  TestCaliNode
//
//  Fixed workout tracking system with proper data models and views
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

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
    let id = UUID()
    var reps: Int?
    var duration: Int?
    var distance: Double?
    var isCompleted: Bool
    let timestamp: Date
    
    init(reps: Int? = nil, duration: Int? = nil, distance: Double? = nil, isCompleted: Bool = false) {
        self.reps = reps
        self.duration = duration
        self.distance = distance
        self.isCompleted = isCompleted
        self.timestamp = Date()
    }
}

struct WorkoutExercise: Identifiable, Codable {
    let id = UUID()
    let exerciseID: String
    var sets: [WorkoutSet]
    var targetSets: Int
    
    init(exerciseID: String, targetSets: Int = 0) {
        self.exerciseID = exerciseID
        self.sets = []
        self.targetSets = targetSets
    }
}

struct WorkoutTemplate: Identifiable, Codable {
    let id = UUID()
    var name: String
    var exercises: [WorkoutExercise]
    let createdAt: Date
    
    init(name: String, exercises: [WorkoutExercise] = []) {
        self.name = name
        self.exercises = exercises
        self.createdAt = Date()
    }
}

struct ActiveWorkout: Identifiable, Codable {
    let id = UUID()
    var name: String
    var exercises: [WorkoutExercise]
    let startTime: Date
    var endTime: Date?
    var isFromTemplate: Bool
    
    var isCompleted: Bool { endTime != nil }
    
    init(name: String, exercises: [WorkoutExercise] = [], isFromTemplate: Bool = false) {
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
    
    // Computed properties for today's stats
    var todaysSets: Int {
        let today = Calendar.current.startOfDay(for: Date())
        let todaysWorkouts = workoutHistory.filter {
            Calendar.current.isDate($0.startTime, inSameDayAs: today)
        }
        return todaysWorkouts.flatMap { $0.exercises }.flatMap { $0.sets }.count
    }
    
    var todaysReps: Int {
        let today = Calendar.current.startOfDay(for: Date())
        let todaysWorkouts = workoutHistory.filter {
            Calendar.current.isDate($0.startTime, inSameDayAs: today)
        }
        return todaysWorkouts.flatMap { $0.exercises }.flatMap { $0.sets }.compactMap { $0.reps }.reduce(0, +)
    }
    
    init() {
        loadExercises()
        loadTemplates()
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
        if let data = UserDefaults.standard.data(forKey: "workoutTemplates"),
           let templates = try? JSONDecoder().decode([WorkoutTemplate].self, from: data) {
            self.templates = templates
        }
    }
    
    private func saveTemplates() {
        if let data = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(data, forKey: "workoutTemplates")
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
            newSet = WorkoutSet(reps: 0)
        case .time:
            newSet = WorkoutSet(duration: 0)
        case .distance:
            newSet = WorkoutSet(distance: 0)
        }
        
        workout.exercises[exerciseIndex].sets.append(newSet)
        activeWorkout = workout
    }
    
    func updateSet(exerciseIndex: Int, setIndex: Int, reps: Int? = nil, duration: Int? = nil, distance: Double? = nil) {
        guard var workout = activeWorkout else { return }
        guard exerciseIndex < workout.exercises.count else { return }
        guard setIndex < workout.exercises[exerciseIndex].sets.count else { return }
        
        var set = workout.exercises[exerciseIndex].sets[setIndex]
        set.reps = reps
        set.duration = duration
        set.distance = distance
        set.isCompleted = (reps ?? 0) > 0 || (duration ?? 0) > 0 || (distance ?? 0) > 0
        
        workout.exercises[exerciseIndex].sets[setIndex] = set
        activeWorkout = workout
    }
    
    func removeSet(exerciseIndex: Int, setIndex: Int) {
        guard var workout = activeWorkout else { return }
        guard exerciseIndex < workout.exercises.count else { return }
        guard setIndex < workout.exercises[exerciseIndex].sets.count else { return }
        
        workout.exercises[exerciseIndex].sets.remove(at: setIndex)
        activeWorkout = workout
    }
    
    func finishWorkout() {
        guard var workout = activeWorkout else { return }
        
        workout.endTime = Date()
        workoutHistory.append(workout)
        activeWorkout = nil
    }
    
    func cancelWorkout() {
        activeWorkout = nil
        currentSession = nil
    }
    
    // MARK: - Simple Session Management (for backward compatibility)
    
    func startWorkout(exerciseID: String) {
        currentSession = WorkoutSession(exerciseID: exerciseID)
    }
    
    func addSet(reps: Int) {
        guard var session = currentSession else { return }
        let newSet = WorkoutSet(reps: reps, isCompleted: true)
        session.sets.append(newSet)
        currentSession = session
    }
    
    func addSet(duration: Int) {
        guard var session = currentSession else { return }
        let newSet = WorkoutSet(duration: duration, isCompleted: true)
        session.sets.append(newSet)
        currentSession = session
    }
    
    func removeLastSet() {
        guard var session = currentSession else { return }
        if !session.sets.isEmpty {
            session.sets.removeLast()
            currentSession = session
        }
    }
    
    func endWorkout() {
        guard let session = currentSession else { return }
        
        // Convert session to completed workout
        let workoutExercise = WorkoutExercise(exerciseID: session.exerciseID)
        var workout = ActiveWorkout(name: "Quick Workout")
        workout.exercises = [workoutExercise]
        workout.exercises[0].sets = session.sets
        workout.endTime = Date()
        
        workoutHistory.append(workout)
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
}

// MARK: - REQUIREMENT 1: Main Workout View (Start Blank or Create Template)

struct WorkoutTrackerView: View {
    @ObservedObject var workoutManager: WorkoutManager
    
    var body: some View {
        NavigationView {
            Group {
                if let activeWorkout = workoutManager.activeWorkout {
                    // Show active workout
                    ActiveWorkoutView(workoutManager: workoutManager, workout: activeWorkout)
                } else {
                    // Show start screen with blank workout or create template options
                    WorkoutStartView(workoutManager: workoutManager)
                }
            }
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(item: $workoutManager.currentSession) { session in
            WorkoutSessionView(workoutManager: workoutManager, session: session)
        }
    }
}

// MARK: - Workout Start View (Blank Workout or Create Template)

struct WorkoutStartView: View {
    @ObservedObject var workoutManager: WorkoutManager
    @State private var showingTemplateCreator = false
    
    var body: some View {
        VStack(spacing: 32) { // Increased spacing for minimalist feel
            Spacer(minLength: 20) // Add some top spacing
            
            // Today's Stats
            todaysStatsCard
            
            // Main Action Buttons
            VStack(spacing: 20) { // Increased spacing between buttons
                // Start Blank Workout Button
                Button(action: {
                    workoutManager.startBlankWorkout()
                }) {
                    HStack(spacing: 16) { // More spacing in button
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Start Blank Workout")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20) // Increased vertical padding
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16) // Slightly more rounded
                }
                
                // Create Template Button
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
            .padding(.horizontal, 24) // Increased horizontal padding
            
            // Templates Section
            if !workoutManager.templates.isEmpty {
                templatesSection
            } else {
                // Empty state for templates
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
            
            Spacer() // Push everything up
        }
        .sheet(isPresented: $showingTemplateCreator) {
            TemplateCreatorView(workoutManager: workoutManager)
        }
    }
    
    private var todaysStatsCard: some View {
        let stats = workoutManager.getTodaysStats()
        
        return VStack(spacing: 16) { // Increased spacing
            Text("Today's Progress")
                .font(.title2) // Larger font
                .fontWeight(.semibold)
            
            HStack(spacing: 40) { // More spacing between stats
                VStack(spacing: 8) { // Spacing within each stat
                    Text("\(stats.workouts)")
                        .font(.largeTitle) // Larger numbers
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Workouts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 8) {
                    Text("\(stats.sets)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Sets")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 8) {
                    Text("\(stats.totalReps)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Reps")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(24) // Increased padding
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(20) // More rounded
        .padding(.horizontal, 24) // Increased horizontal margin
    }
    
    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 20) { // Increased spacing
            Text("Workout Templates")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal, 24) // Consistent with other margins
            
            ScrollView {
                LazyVStack(spacing: 16) { // Increased spacing between template rows
                    ForEach(workoutManager.templates) { template in
                        TemplateRow(template: template, workoutManager: workoutManager) {
                            workoutManager.startWorkoutFromTemplate(template)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(maxHeight: 200) // Limit height to keep it minimalist
        }
    }
    

}

// MARK: - Template Row

struct TemplateRow: View {
    let template: WorkoutTemplate
    let workoutManager: WorkoutManager
    let onStart: () -> Void
    
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
                    
                    // Show exercise preview
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
                    .foregroundColor(.blue)
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - REQUIREMENT 2 & 3: Active Workout View (Add Exercises Button + Set Tracking)

struct ActiveWorkoutView: View {
    @ObservedObject var workoutManager: WorkoutManager
    let workout: ActiveWorkout
    @State private var showingExercisePicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Workout Header
            workoutHeader
            
            // Exercise List or Empty State
            if workout.exercises.isEmpty {
                emptyWorkoutView
            } else {
                exercisesList
            }
        }
        .navigationBarBackButtonHidden()
        .navigationBarItems(
            leading: Button("Cancel") {
                workoutManager.cancelWorkout()
            },
            trailing: Button("Finish") {
                workoutManager.finishWorkout()
            }
            .disabled(workout.exercises.isEmpty)
        )
    }
    
    private var workoutHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(workout.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Started \(workout.startTime, style: .time)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // REQUIREMENT 2: Add Exercise Button
                Button("Add Exercise") {
                    showingExercisePicker = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            // Workout Stats
            HStack(spacing: 30) {
                VStack {
                    Text("\(workout.exercises.count)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(totalSets)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Sets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(totalReps)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Reps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemBackground))
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView(workoutManager: workoutManager)
        }
    }
    
    private var emptyWorkoutView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "dumbbell")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No exercises added yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Tap 'Add Exercise' to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("Add Exercise") {
                showingExercisePicker = true
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding(20)
    }
    
    // REQUIREMENT 3: Exercise List with Set Count and Reps
    private var exercisesList: some View {
        ScrollView {
            LazyVStack(spacing: 20) { // Increased spacing between exercise cards
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
            .padding(.horizontal, 24) // Increased horizontal padding
            .padding(.vertical, 20) // Increased vertical padding
        }
        .onTapGesture {
            // Focus state will handle keyboard dismissal through the SetRow components
        }
    }
    
    private var totalSets: Int {
        workout.exercises.reduce(0) { $0 + $1.sets.count }
    }
    
    private var totalReps: Int {
        workout.exercises.flatMap { $0.sets }.compactMap { $0.reps }.reduce(0, +)
    }
}

// MARK: - Exercise Workout Card (Shows Sets and Reps)

struct ExerciseWorkoutCard: View {
    let exercise: Exercise
    let workoutExercise: WorkoutExercise
    let exerciseIndex: Int
    @ObservedObject var workoutManager: WorkoutManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) { // Increased spacing
            // Exercise Header
            HStack(spacing: 16) { // Increased spacing
                Text(exercise.emoji)
                    .font(.system(size: 28)) // Slightly larger
                
                VStack(alignment: .leading, spacing: 6) { // Increased spacing
                    Text(exercise.name)
                        .font(.title3) // Larger font
                        .fontWeight(.semibold)
                    
                    Text("\(workoutExercise.sets.count) sets")
                        .font(.subheadline) // Larger font
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Add Set Button
                Button("Add Set") {
                    workoutManager.addSetToExercise(exerciseIndex: exerciseIndex)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            // Sets List
            if !workoutExercise.sets.isEmpty {
                VStack(spacing: 12) { // Increased spacing between sets
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
        .padding(20) // Increased padding
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16) // More rounded
    }
}

// MARK: - Set Row (Individual Set with Reps/Time Input)

struct SetRow: View {
    let setNumber: Int
    let set: WorkoutSet
    let exercise: Exercise
    let onUpdate: (Int?, Int?, Double?) -> Void
    let onDelete: () -> Void
    
    @State private var repsInput: String = ""
    @State private var durationInput: String = ""
    @FocusState private var isInputFocused: Bool // Add focus state
    
    var body: some View {
        HStack(spacing: 16) { // Increased spacing
            Text("Set \(setNumber)")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 70, alignment: .leading) // Slightly wider
            
            // Input based on exercise type
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
                        .onChange(of: repsInput) { newValue in
                            let reps = Int(newValue) ?? 0
                            onUpdate(reps > 0 ? reps : nil, nil, nil)
                        }
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    isInputFocused = false
                                }
                            }
                        }
                    
                    Text("reps")
                        .font(.subheadline) // Larger font
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
                        .onChange(of: durationInput) { newValue in
                            let duration = Int(newValue) ?? 0
                            onUpdate(nil, duration > 0 ? duration : nil, nil)
                        }
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    isInputFocused = false
                                }
                            }
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
                        .onChange(of: durationInput) { newValue in
                            let distance = Double(newValue) ?? 0
                            onUpdate(nil, nil, distance > 0 ? distance : nil)
                        }
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    isInputFocused = false
                                }
                            }
                        }
                    
                    Text("m")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Completed indicator
            if set.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3) // Slightly larger
                    .foregroundColor(.green)
            }
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.title3) // Slightly larger
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 16) // Increased padding
        .padding(.vertical, 12) // Increased padding
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(12) // More rounded
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            isInputFocused = false
        }
    }
}

// MARK: - REQUIREMENT 2: Exercise Picker (Dropdown Menu)

struct ExercisePickerView: View {
    @ObservedObject var workoutManager: WorkoutManager
    @Environment(\.presentationMode) var presentationMode
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
                // Category Selector
                categorySelector
                
                // Exercise List
                exerciseList
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
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
                                .fill(selectedCategory == category.0 ? Color.blue : Color(UIColor.secondarySystemBackground))
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
                        workoutManager.addExerciseToWorkout(exercise.id)
                        presentationMode.wrappedValue.dismiss()
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
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .clipShape(Capsule())
                            }
                            
                            Spacer()
                            
                            Image(systemName: "plus.circle")
                                .font(.title2)
                                .foregroundColor(.blue)
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

// MARK: - REQUIREMENT 4: Template Creator

struct TemplateCreatorView: View {
    @ObservedObject var workoutManager: WorkoutManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var templateName = ""
    @State private var selectedExercises: [WorkoutExercise] = []
    @State private var showingExercisePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Template Name Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Template Name")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    TextField("Enter template name", text: $templateName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Selected Exercises Section
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
                
                // Create Template Button
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
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $showingExercisePicker) {
                TemplateExercisePickerView(
                    workoutManager: workoutManager,
                    selectedExercises: $selectedExercises
                )
            }
        }
    }
}

// MARK: - Template Exercise Row (Shows exercise with target sets)

struct TemplateExerciseRow: View {
    let exercise: Exercise
    let targetSets: Int
    let onUpdateSets: (Int) -> Void
    let onRemove: () -> Void
    
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
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
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
                    .onChange(of: setsInput) { newValue in
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
    @Environment(\.presentationMode) var presentationMode
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
                // Category Selector
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
                                        .fill(selectedCategory == category.0 ? Color.blue : Color(UIColor.secondarySystemBackground))
                                )
                                .foregroundColor(selectedCategory == category.0 ? .white : .primary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
                
                // Exercise List
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
                                            .background(Color.blue.opacity(0.2))
                                            .foregroundColor(.blue)
                                            .clipShape(Capsule())
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                                        .font(.title2)
                                        .foregroundColor(isSelected ? .green : .blue)
                                }
                                .padding(16)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
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
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(selectedExercises.isEmpty)
            )
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
    @State private var repsInput = ""
    @State private var durationInput = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if let exercise = workoutManager.getExercise(by: session.exerciseID) {
                    // Exercise Header
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
                    
                    // Current Sets
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
                                    
                                    Button(action: workoutManager.removeLastSet) {
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
                    
                    // Add Set Section
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
                                    workoutManager.addSet(reps: reps)
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
                                    workoutManager.addSet(duration: duration)
                                    durationInput = ""
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(durationInput.isEmpty || Int(durationInput) == nil)
                        }
                    }
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button("Finish Workout") {
                        workoutManager.endWorkout()
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
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    workoutManager.cancelWorkout()
                    presentationMode.wrappedValue.dismiss()
                }
            )
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
