//
//  ProgressDashboard.swift
//  TestCaliNode
//
//  Migrated to Electric Gradient Color System - Minimalist Style
//

import SwiftUI

struct ProgressDashboard: View {
    @ObservedObject var skillManager: GlobalSkillManager
    @StateObject private var colorManager = {
        AppColorManager(useElectricTheme: true)
    }()
    @State private var showResetConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // MARK: - Level & XP Header
                levelHeader
                
                // MARK: - Skill Tree Overview
                skillTreeOverview
                
                // MARK: - Danger Zone
                DangerZoneSection(
                    skillManager: skillManager,
                    showResetConfirmation: $showResetConfirmation
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 120)
        }
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            ProgressDashboard.markAsMigrated()
        }
    }
    
    // MARK: - Level Header
    private var levelHeader: some View {
        VStack(spacing: 24) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Text(skillManager.levelEmoji)
                            .font(.system(size: 48))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Level \(skillManager.currentLevel)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(colorManager.theme.primary)
                            
                            Text(skillManager.levelTitle)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(colorManager.theme.text)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("\(skillManager.totalXP)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(colorManager.theme.accent)
                    
                    Text("Total XP")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(colorManager.theme.textSecondary)
                }
            }
            
            // XP Progress to Next Level
            VStack(spacing: 12) {
                HStack {
                    Text("Progress to Next Level")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(colorManager.theme.text)
                    
                    Spacer()
                    
                    Text("\(skillManager.xpProgressToNextLevel) / \(skillManager.xpForNextLevel - skillManager.xpForCurrentLevel) XP")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(colorManager.theme.textSecondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 12)
                        
                        // Progress - Electric Gradient
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorManager.vibrantButtonGradient)
                            .frame(width: geometry.size.width * skillManager.levelProgress, height: 12)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8), value: skillManager.levelProgress)
                    }
                }
                .frame(height: 12)
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 10)
        )
    }
    
    
    // MARK: - Skill Tree Overview
    private var skillTreeOverview: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Skill Trees")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(colorManager.theme.text)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 20) {
                ForEach(["pull", "push", "core", "legs"], id: \.self) { treeID in
                    ModernTreeCard(
                        treeID: treeID,
                        skillManager: skillManager,
                        colorManager: colorManager
                    )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 10)
        )
    }
    
    
}


// MARK: - Modern Tree Card
struct ModernTreeCard: View {
    let treeID: String
    @ObservedObject var skillManager: GlobalSkillManager
    var colorManager: AppColorManager
    
    private func treeInfo(for treeID: String) -> (name: String, emoji: String, color: Color, gradient: LinearGradient) {
        switch treeID {
        case "pull": 
            return ("Pull", "🆙", colorManager.theme.primary, 
                   LinearGradient(colors: [colorManager.theme.primary, colorManager.theme.primary.opacity(0.7)], 
                                startPoint: .topLeading, endPoint: .bottomTrailing))
        case "push": 
            return ("Push", "🙌", colorManager.theme.tertiary,
                   LinearGradient(colors: [colorManager.theme.tertiary, colorManager.theme.tertiary.opacity(0.7)], 
                                startPoint: .topLeading, endPoint: .bottomTrailing))
        case "core": 
            return ("Core", "🧱", colorManager.theme.secondary,
                   LinearGradient(colors: [colorManager.theme.secondary, colorManager.theme.secondary.opacity(0.7)], 
                                startPoint: .topLeading, endPoint: .bottomTrailing))
        case "legs": 
            return ("Legs", "🦿", colorManager.theme.accent,
                   LinearGradient(colors: [colorManager.theme.accent, colorManager.theme.accent.opacity(0.7)], 
                                startPoint: .topLeading, endPoint: .bottomTrailing))
        default: 
            return ("Unknown", "❓", colorManager.theme.text,
                   LinearGradient(colors: [colorManager.theme.text, colorManager.theme.text.opacity(0.7)], 
                                startPoint: .topLeading, endPoint: .bottomTrailing))
        }
    }
    
    var body: some View {
        let progress = skillManager.getTreeProgress(treeID)
        let info = treeInfo(for: treeID)
        let progressPercent = progress.total > 0 ? Double(progress.unlocked) / Double(progress.total) : 0
        
        VStack(spacing: 20) {
            // Icon and Title
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(info.gradient)
                        .frame(width: 70, height: 70)
                        .shadow(color: info.color.opacity(0.3), radius: 15, x: 0, y: 8)
                    
                    Text(info.emoji)
                        .font(.system(size: 32))
                }
                
                Text(info.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(colorManager.theme.text)
            }
            
            // Progress Section
            VStack(spacing: 12) {
                // Progress Number
                HStack {
                    Text("\(progress.unlocked)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(info.color)
                    
                    Text("/")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(colorManager.theme.textSecondary)
                    
                    Text("\(progress.total)")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(colorManager.theme.textSecondary)
                }
                
                // Progress Bar
                VStack(spacing: 6) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 8)
                            
                            // Progress Fill
                            RoundedRectangle(cornerRadius: 8)
                                .fill(info.gradient)
                                .frame(width: geometry.size.width * progressPercent, height: 8)
                                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: progressPercent)
                        }
                    }
                    .frame(height: 8)
                    
                    // Percentage
                    Text("\(Int(progressPercent * 100))% Complete")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(colorManager.theme.textSecondary)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.tertiarySystemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(info.color.opacity(0.1), lineWidth: 1)
        )
    }
}


// MARK: - Progress Tab Migration
extension ProgressDashboard {
    static func markAsMigrated() {
        ColorMigrationHelper.markComponentMigrated("ProgressDashboard")
        ColorMigrationHelper.markComponentMigrated("ModernTreeCard")
    }
}
