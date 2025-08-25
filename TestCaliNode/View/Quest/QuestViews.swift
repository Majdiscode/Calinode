//
//  QuestViews.swift
//  TestCaliNode
//
//  Adaptive Quest System Views
//

import SwiftUI

// MARK: - Main Quest View

struct QuestView: View {
    @ObservedObject private var questManager = QuestManager.shared
    @StateObject private var colorManager = AppColorManager(useElectricTheme: true)
    @State private var showingAssessment = false
    @Binding var selectedTab: Int // Add binding for tab navigation
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // User Progress Header
                    if questManager.hasCompletedAssessment {
                        userProgressHeader
                    }
                    
                    // Daily Quests Section
                    if questManager.hasCompletedAssessment {
                        // Show completion celebration if all quests done
                        if questManager.userProgress.allQuestsCompletedToday {
                            completionCelebration
                        }
                        
                        dailyQuestsSection
                        
                        // Show readiness tests if available
                        if !questManager.userProgress.availableReadinessTests.isEmpty {
                            readinessTestsSection
                        }
                    } else {
                        assessmentPrompt
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
            .navigationTitle("Daily Quests")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if questManager.hasCompletedAssessment {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Retake Assessment") {
                            showingAssessment = true
                        }
                        .font(.caption)
                    }
                }
            }
            .sheet(isPresented: $showingAssessment) {
                FitnessAssessmentView()
            }
        }
        .onAppear {
            questManager.refreshAvailableQuests()
        }
    }
    
    // MARK: - Quest Interaction Handling
    private func handleQuestTap(quest: Quest) {
        // Don't handle taps on completed quests
        guard !quest.isCompleted else { return }
        
        switch quest.title {
        case "Start Your Journey":
            // Navigate to workout tab (tab index 1)
            selectedTab = 1
        case "Take the Assessment":
            // Show assessment popup
            showingAssessment = true
        default:
            // Handle other quest types as needed
            print("Quest tapped: \(quest.title)")
        }
    }
    
    // MARK: - User Progress Header
    private var userProgressHeader: some View {
        VStack(spacing: 20) {
            // Fitness Level & Streak
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Text(questManager.userProfile.fitnessLevel.emoji)
                            .font(.system(size: 36))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(questManager.userProfile.fitnessLevel.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(colorManager.theme.text)
                            
                            Text("Level \(questManager.userProgress.currentStreak)")
                                .font(.subheadline)
                                .foregroundColor(colorManager.theme.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                // Streak & Currency
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("🔥")
                        Text("\(questManager.userProgress.currentStreak)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(colorManager.theme.accent)
                    }
                    
                    HStack(spacing: 8) {
                        Text("🪙")
                        Text("\(questManager.userProgress.caliCoins)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(colorManager.theme.secondary)
                    }
                }
            }
            
            // Quest Progress Bar
            VStack(spacing: 12) {
                HStack {
                    Text("Today's Progress")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(colorManager.theme.text)
                    
                    Spacer()
                    
                    Text("\(questManager.completedQuestsToday)/\(questManager.totalQuestsToday) completed")
                        .font(.subheadline)
                        .foregroundColor(colorManager.theme.textSecondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorManager.vibrantButtonGradient)
                            .frame(
                                width: geometry.size.width * (questManager.totalQuestsToday > 0 ? Double(questManager.completedQuestsToday) / Double(questManager.totalQuestsToday) : 0),
                                height: 8
                            )
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: questManager.completedQuestsToday)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 10)
        )
    }
    
    // MARK: - Completion Celebration
    private var completionCelebration: some View {
        VStack(spacing: 16) {
            HStack {
                Text("All Quests Complete!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colorManager.theme.primary)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Amazing work! You've completed all your daily quests.")
                    .font(.subheadline)
                    .foregroundColor(colorManager.theme.text)
                
                if questManager.userProgress.showTomorrowPreview {
                    Text("Come back tomorrow for new challenges and keep your streak alive!")
                        .font(.subheadline)
                        .foregroundColor(colorManager.theme.secondary)
                        .fontWeight(.medium)
                }
                
                // Streak celebration
                if questManager.userProgress.currentStreak > 1 {
                    Text("\(questManager.userProgress.currentStreak) day streak")
                        .font(.subheadline)
                        .foregroundColor(colorManager.theme.accent)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [colorManager.theme.primary.opacity(0.1), colorManager.theme.accent.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(colorManager.theme.primary.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Readiness Tests Section
    private var readinessTestsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("⚡ Skill Readiness Tests")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(colorManager.theme.text)
            
            Text("Your recent performance has unlocked advanced skill tests!")
                .font(.subheadline)
                .foregroundColor(colorManager.theme.textSecondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(questManager.userProgress.availableReadinessTests) { test in
                    ReadinessTestCard(test: test, colorManager: colorManager)
                }
            }
        }
    }
    
    // MARK: - Daily Quests Section
    private var dailyQuestsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Choose Your Challenge")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(colorManager.theme.text)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 24)
            ], spacing: 24) {
                ForEach(questManager.dailyQuests) { quest in
                    QuestCard(quest: quest, colorManager: colorManager) {
                        handleQuestTap(quest: quest)
                    }
                }
            }
        }
    }
    
    // MARK: - Assessment Prompt
    private var assessmentPrompt: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    colorManager.theme.primary.opacity(0.2),
                                    colorManager.theme.tertiary.opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Text("📊")
                        .font(.system(size: 48))
                }
                
                VStack(spacing: 16) {
                    Text("Ready to Start?")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(colorManager.theme.text)
                    
                    Text("Complete a quick fitness assessment to get personalized daily quests tailored to your current abilities.")
                        .font(.body)
                        .foregroundColor(colorManager.theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Button(action: {
                    showingAssessment = true
                }) {
                    HStack(spacing: 12) {
                        Text("🚀")
                        Text("Take Fitness Assessment")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(colorManager.theme.buttonGradient)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Quest Card

struct QuestCard: View {
    let quest: Quest
    let colorManager: AppColorManager
    let onTap: (() -> Void)?
    @State private var animateProgress = false
    @State private var isPressed = false
    
    init(quest: Quest, colorManager: AppColorManager, onTap: (() -> Void)? = nil) {
        self.quest = quest
        self.colorManager = colorManager
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            VStack(alignment: .leading, spacing: 24) {
                // Quest Header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(quest.difficulty.title)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(difficultyColor)
                            .textCase(.uppercase)
                            .tracking(1.2)
                        
                        Text(quest.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(colorManager.theme.text)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    if quest.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "arrow.right.circle")
                            .font(.title2)
                            .foregroundColor(colorManager.theme.textSecondary.opacity(0.6))
                    }
                }
                
                // Quest Description
                Text(quest.description)
                    .font(.body)
                    .foregroundColor(colorManager.theme.textSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Progress Bar (for incomplete quests)
                if !quest.isCompleted {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Progress")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(colorManager.theme.textSecondary)
                            
                            Spacer()
                            
                            Text("\(quest.progress)/\(quest.targetValue)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(colorManager.theme.text)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(difficultyColor)
                                    .frame(
                                        width: geometry.size.width * (animateProgress ? quest.progressPercentage : 0),
                                        height: 8
                                    )
                                    .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animateProgress)
                            }
                        }
                        .frame(height: 8)
                    }
                    .onAppear {
                        animateProgress = true
                    }
                }
                
                // Rewards Section
                HStack(spacing: 24) {
                    HStack(spacing: 8) {
                        Text("\(quest.xpReward) XP")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorManager.theme.accent)
                    }
                    
                    HStack(spacing: 8) {
                        Text("\(quest.coinReward) coins")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorManager.theme.secondary)
                    }
                    
                    Spacer()
                    
                    if quest.isExpired && !quest.isCompleted {
                        Text("EXPIRED")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(28)
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, perform: {}) { pressing in
            isPressed = pressing
        }
        .disabled(quest.isCompleted)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(quest.isCompleted ? Color.green.opacity(0.05) : Color(red: 0.11, green: 0.11, blue: 0.13))
                .shadow(
                    color: Color.black.opacity(0.4),
                    radius: 16,
                    x: 0,
                    y: 6
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            quest.isCompleted ? .green.opacity(0.3) : Color(red: 0.22, green: 0.22, blue: 0.24),
                            lineWidth: 1.5
                        )
                )
        )
    }
    
    private var difficultyColor: Color {
        switch quest.difficulty {
        case .starter: return .green
        case .challenger: return .orange
        case .beastMode: return .red
        case .readinessTest: return .purple
        }
    }
    
    private var difficultyGradient: LinearGradient {
        switch quest.difficulty {
        case .starter:
            return LinearGradient(colors: [.green, .green.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
        case .challenger:
            return LinearGradient(colors: [.orange, .orange.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
        case .beastMode:
            return LinearGradient(colors: [.red, .red.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
        case .readinessTest:
            return LinearGradient(colors: [.purple, .purple.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
        }
    }
}

// MARK: - Fitness Assessment View

struct FitnessAssessmentView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var questManager = QuestManager.shared
    @StateObject private var colorManager = AppColorManager(useElectricTheme: true)
    
    @State private var maxPushUps: String = ""
    @State private var maxPullUps: String = ""
    @State private var maxPlankSeconds: String = ""
    @State private var maxSquats: String = ""
    @State private var showingInstructions = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    if showingInstructions {
                        instructionsView
                    } else {
                        assessmentForm
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .navigationTitle("Fitness Assessment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Instructions View
    private var instructionsView: some View {
        VStack(spacing: 24) {
            Text("💪")
                .font(.system(size: 64))
            
            Text("Quick Fitness Check")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(colorManager.theme.text)
            
            Text("This quick assessment helps us create personalized daily quests that match your current fitness level. Don't worry about being perfect - we'll adjust as you progress!")
                .font(.body)
                .foregroundColor(colorManager.theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                AssessmentInstructionRow(
                    emoji: "🙏",
                    title: "Push-ups",
                    instruction: "How many push-ups can you do in a row? (Use knee push-ups if needed)"
                )
                
                AssessmentInstructionRow(
                    emoji: "🎆",
                    title: "Pull-ups",
                    instruction: "How many pull-ups can you do? (Enter 0 if you can't do any yet)"
                )
                
                AssessmentInstructionRow(
                    emoji: "🏗️",
                    title: "Plank",
                    instruction: "How long can you hold a plank? (In seconds)"
                )
                
                AssessmentInstructionRow(
                    emoji: "🧎",
                    title: "Squats",
                    instruction: "How many bodyweight squats can you do in a row?"
                )
            }
            
            Button("Start Assessment") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingInstructions = false
                }
            }
            .font(.headline)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(colorManager.theme.buttonGradient)
            .foregroundColor(.white)
            .cornerRadius(16)
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Assessment Form
    private var assessmentForm: some View {
        VStack(spacing: 24) {
            Text("Enter Your Current Max")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(colorManager.theme.text)
            
            Text("Be honest - this helps us create the perfect challenge level for you!")
                .font(.subheadline)
                .foregroundColor(colorManager.theme.textSecondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 20) {
                AssessmentInputRow(
                    emoji: "🙏",
                    title: "Push-ups",
                    input: $maxPushUps,
                    placeholder: "e.g. 10"
                )
                
                AssessmentInputRow(
                    emoji: "🎆",
                    title: "Pull-ups",
                    input: $maxPullUps,
                    placeholder: "e.g. 3 (or 0)"
                )
                
                AssessmentInputRow(
                    emoji: "🏗️",
                    title: "Plank (seconds)",
                    input: $maxPlankSeconds,
                    placeholder: "e.g. 60"
                )
                
                AssessmentInputRow(
                    emoji: "🧎",
                    title: "Squats",
                    input: $maxSquats,
                    placeholder: "e.g. 25"
                )
            }
            
            Spacer(minLength: 20)
            
            Button("Complete Assessment") {
                completeAssessment()
            }
            .font(.headline)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isFormValid ? colorManager.theme.buttonGradient : LinearGradient(
                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(isFormValid ? .white : .gray)
            .cornerRadius(16)
            .disabled(!isFormValid)
            
            Button("Back to Instructions") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingInstructions = true
                }
            }
            .foregroundColor(colorManager.theme.primary)
        }
    }
    
    private var isFormValid: Bool {
        !maxPushUps.isEmpty && !maxPullUps.isEmpty && !maxPlankSeconds.isEmpty && !maxSquats.isEmpty
    }
    
    private func completeAssessment() {
        let pushUps = Int(maxPushUps) ?? 0
        let pullUps = Int(maxPullUps) ?? 0
        let plankSeconds = Int(maxPlankSeconds) ?? 0
        let squats = Int(maxSquats) ?? 0
        
        questManager.completeAssessment(
            maxPushUps: pushUps,
            maxPullUps: pullUps,
            maxPlankSeconds: plankSeconds,
            maxSquats: squats
        )
        
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Helper Views

struct AssessmentInstructionRow: View {
    let emoji: String
    let title: String
    let instruction: String
    
    var body: some View {
        HStack(spacing: 16) {
            Text(emoji)
                .font(.system(size: 24))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(instruction)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

struct AssessmentInputRow: View {
    let emoji: String
    let title: String
    @Binding var input: String
    let placeholder: String
    
    var body: some View {
        HStack(spacing: 16) {
            Text(emoji)
                .font(.system(size: 24))
                .frame(width: 40)
            
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField(placeholder, text: $input)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .frame(width: 100)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
    }
}


// MARK: - Readiness Test Card

struct ReadinessTestCard: View {
    let test: SkillReadinessTest
    let colorManager: AppColorManager
    @State private var showingTestDetails = false
    
    var body: some View {
        Button(action: {
            showingTestDetails = true
        }) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Text("⚡")
                        .font(.system(size: 32))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("READINESS TEST")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                        
                        Text(test.testTitle)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorManager.theme.text)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle")
                        .font(.title2)
                        .foregroundColor(.purple)
                }
                
                HStack {
                    Text("🎯")
                    Text("Unlock: \(test.targetSkillName)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(colorManager.theme.primary)
                }
                
                Text(test.testDescription)
                    .font(.subheadline)
                    .foregroundColor(colorManager.theme.textSecondary)
                    .lineLimit(3)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.purple, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ReadinessTestDetailView: View {
    let test: SkillReadinessTest
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var colorManager = AppColorManager(useElectricTheme: true)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Text("⚡")
                            .font(.system(size: 48))
                        
                        Text(test.testTitle)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(colorManager.theme.text)
                        
                        Text("Ready to unlock \(test.targetSkillName)?")
                            .font(.subheadline)
                            .foregroundColor(colorManager.theme.textSecondary)
                    }
                    
                    Text(test.testDescription)
                        .font(.body)
                        .foregroundColor(colorManager.theme.text)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.vertical, 32)
            }
            .navigationTitle("Readiness Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
