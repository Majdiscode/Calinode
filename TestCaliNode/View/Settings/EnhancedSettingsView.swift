//
//  EnhancedSettingsView.swift
//  TestCaliNode
//
//  Migrated to Electric Gradient Color System
//  Updated with AppColorSystem integration
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Notification Names
extension Notification.Name {
    static let resetAllWorkoutData = Notification.Name("resetAllWorkoutData")
}

struct EnhancedSettingsView: View {
    @ObservedObject var skillManager: GlobalSkillManager
    @StateObject private var colorManager = {
        AppColorManager(useElectricTheme: true)
    }()
    @AppStorage("isDarkMode") private var isDarkMode = true
    @State private var showingFeatureFlagPanel = false
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section("Profile") {
                    ProfileRow(skillManager: skillManager, colorManager: colorManager)
                }
                
                // Appearance Section
                Section("Appearance") {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                        .tint(colorManager.theme.primary)
                    
                    Toggle("Electric Theme", isOn: $colorManager.isElectricThemeEnabled)
                        .tint(colorManager.theme.primary)
                        .onChange(of: colorManager.isElectricThemeEnabled) { _, enabled in
                            if enabled {
                                EnhancedSettingsView.markAsMigrated()
                            }
                        }
                }
                
                // Features Section
                Section("Features") {
                    FeatureToggleRow(
                        flag: .enhancedAnimations,
                        title: "Enhanced Animations",
                        description: "Smooth animations in skill trees",
                        colorManager: colorManager
                    )
                    
                    FeatureToggleRow(
                        flag: .betterProgress,
                        title: "Detailed Progress",
                        description: "Enhanced progress tracking and analytics",
                        colorManager: colorManager
                    )
                    
                    FeatureToggleRow(
                        flag: .achievementBadges,
                        title: "Achievement Badges",
                        description: "Unlock and display achievement badges",
                        colorManager: colorManager
                    )
                }
                
                // Data Management Section
                Section("Data Management") {
                    Button("Reset All Data") {
                        showingResetAlert = true
                    }
                    .foregroundColor(colorManager.theme.error)
                }
                
                // Debug Section (only in debug builds)
                #if DEBUG
                Section("Debug") {
                    Button("Feature Flags Panel") {
                        showingFeatureFlagPanel = true
                    }
                    .foregroundColor(colorManager.theme.info)
                }
                #endif
                
                // About Section
                Section("About") {
                    NavigationLink("About App") {
                        AboutView()
                    }
                    
                    NavigationLink("Help & Support") {
                        HelpSupportView()
                    }
                }
                
                // Account Section
                Section("Account") {
                    NavigationLink("Sign Out") {
                        LogoutConfirmationView()
                    }
                    .foregroundColor(colorManager.theme.error)
                }
            }
            .navigationTitle("Settings")
            .background(colorManager.subtleBackgroundGradient)
        }
        .sheet(isPresented: $showingFeatureFlagPanel) {
            FeatureFlagDebugPanel()
        }
        .alert("Reset All Data", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will permanently delete all your progress. This action cannot be undone.")
        }
    }
    
    private func resetAllData() {
        print("🔄 Starting complete data reset...")
        
        // IMPORTANT: Reset all in-memory state first
        DispatchQueue.main.async {
            // Reset Skills - clear published arrays immediately
            self.skillManager.unlockedSkills.removeAll()
            self.skillManager.resetAllProgress()
            
            // Reset Quests - clear all published properties immediately
            QuestManager.shared.dailyQuests.removeAll()
            QuestManager.shared.hasCompletedAssessment = false
            QuestManager.shared.userProfile = UserCapabilityProfile()
            QuestManager.shared.userProgress = UserProgress()
            QuestManager.shared.resetAllQuests()
            
            // Reset Workouts and Templates (using notification pattern)
            NotificationCenter.default.post(name: .resetAllWorkoutData, object: nil)
            
            // Reset Streaks - clear all published properties immediately
            StreakManager.shared.streakData = StreakData()
            StreakManager.shared.resetAllStreaks()
            
            // Reset Feature Flags
            FeatureFlagService.shared.resetToDefaults()
            
            // Clear UserDefaults
            self.clearAllUserDefaults()
            
            // Clear Firebase data
            self.clearFirebaseData()
            
            // Force UI refresh by toggling app state if needed
            self.isDarkMode.toggle()
            self.isDarkMode.toggle()
            
            print("✅ Complete data reset finished - UI should refresh")
        }
    }
    
    
    private func clearAllUserDefaults() {
        let defaults = UserDefaults.standard
        
        // Clear all app-specific keys
        let keysToRemove = [
            "unlockedSkills",
            "workoutTemplates",
            "workoutHistory",
            "userCapabilityProfile",
            "userProgress",
            "streakData",
            "isDarkMode",
            "hasCompletedOnboarding",
            "lastAppVersion"
        ]
        
        keysToRemove.forEach { key in
            defaults.removeObject(forKey: key)
        }
        
        // Reset dark mode to default
        isDarkMode = true
        
        print("📱 UserDefaults cleared")
    }
    
    private func clearFirebaseData() {
        guard let user = Auth.auth().currentUser else {
            print("⚠️ No Firebase user to clear data for")
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)
        
        // Delete the entire user document and all subcollections
        userRef.delete { error in
            if let error = error {
                print("❌ Error deleting Firebase user data: \(error.localizedDescription)")
            } else {
                print("🔥 Firebase user data deleted")
            }
        }
        
        // Delete subcollections separately as Firestore doesn't delete them automatically
        deleteFirebaseSubcollections(userRef: userRef)
    }
    
    private func deleteFirebaseSubcollections(userRef: DocumentReference) {
        let subcollections = ["workouts", "quests", "streaks"]
        
        subcollections.forEach { collectionName in
            userRef.collection(collectionName).getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error getting \(collectionName) documents: \(error.localizedDescription)")
                    return
                }
                
                let batch = Firestore.firestore().batch()
                snapshot?.documents.forEach { document in
                    batch.deleteDocument(document.reference)
                }
                
                batch.commit { error in
                    if let error = error {
                        print("❌ Error deleting \(collectionName): \(error.localizedDescription)")
                    } else {
                        print("🗑️ Deleted \(collectionName) collection")
                    }
                }
            }
        }
    }
}

// MARK: - Settings Tab Migration Status
extension EnhancedSettingsView {
    static func markAsMigrated() {
        // Mark this component as migrated to electric theme
        ColorMigrationHelper.markComponentMigrated("EnhancedSettingsView")
        ColorMigrationHelper.markComponentMigrated("ProfileRow")
        ColorMigrationHelper.markComponentMigrated("FeatureToggleRow")
        ColorMigrationHelper.markComponentMigrated("FeatureRow")
    }
}
