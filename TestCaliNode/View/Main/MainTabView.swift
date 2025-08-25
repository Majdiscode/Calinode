//
//  MainTabView.swift
//  TestCaliNode
//
//  CLEAN VERSION - Quest badges and integrations removed
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var skillManager = {
        GlobalSkillManager()
    }()
    @StateObject private var workoutManager = {
        WorkoutManager()
    }()
    @ObservedObject private var questManager = QuestManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Skills Tab
            SkillTreeContainer(skillManager: skillManager)
                .tabItem {
                    Label("Skills", systemImage: "tree")
                }
                .tag(0)
                // REMOVED: quest badge
            
            // Workout Tracker Tab
            WorkoutTrackerView(workoutManager: workoutManager)
                .tabItem {
                    Label("Workouts", systemImage: "figure.strengthtraining.traditional")
                }
                .tag(1)
            
            // Quests Tab (Blank)
            QuestView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Quests", systemImage: "flag.fill")
                }
                .tag(2)
                // REMOVED: quest badge
            
            // Progress Tab
            ProgressDashboard(skillManager: skillManager)
                .tabItem {
                    Label("Progress", systemImage: "chart.pie")
                }
                .tag(3)

            // Settings Tab
            EnhancedSettingsView(skillManager: skillManager)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(4)
        }
        .onAppear {
            // Connect managers for quest system integration
            questManager.setSkillManager(skillManager)
            questManager.setWorkoutManager(workoutManager)
        }
    }
}
