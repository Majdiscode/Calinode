//
//  EnhancedSettingsView.swift
//  TestCaliNode
//
//  Cleaned - Quest Manager References Removed
//

import SwiftUI

struct EnhancedSettingsView: View {
    @ObservedObject var skillManager: GlobalSkillManager
    // REMOVED: questManager parameter
    @AppStorage("isDarkMode") private var isDarkMode = true
    @State private var showingFeatureFlagPanel = false
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section("Profile") {
                    ProfileRow(skillManager: skillManager)
                }
                
                // Appearance Section
                Section("Appearance") {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                }
                
                // Features Section
                Section("Features") {
                    FeatureToggleRow(
                        flag: .enhancedAnimations,
                        title: "Enhanced Animations",
                        description: "Smooth animations in skill trees"
                    )
                    
                    FeatureToggleRow(
                        flag: .betterProgress,
                        title: "Detailed Progress",
                        description: "Enhanced progress tracking and analytics"
                    )
                    
                    FeatureToggleRow(
                        flag: .achievementBadges,
                        title: "Achievement Badges",
                        description: "Unlock and display achievement badges"
                    )
                    
                    // REMOVED: Quest notifications toggle
                }
                
                // Debug Section (only in debug builds)
                #if DEBUG
                Section("Debug") {
                    Button("Feature Flags Panel") {
                        showingFeatureFlagPanel = true
                    }
                    
                    Button("Reset All Data") {
                        showingResetAlert = true
                    }
                    .foregroundColor(.red)
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
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
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
        skillManager.resetAllProgress()
        // REMOVED: Quest manager reset
        FeatureFlagService.shared.resetToDefaults()
        print("🔄 All data reset")
    }
}
