//
//  ProgressDashboard.swift
//  TestCaliNode
//
//  Achievement-Free Version - Syntax Fixed
//

import SwiftUI

struct ProgressDashboard: View {
    @ObservedObject var skillManager: GlobalSkillManager
    @State private var selectedCard: ProgressCardType? = nil
    @State private var showDetail = false
    @State private var showResetConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Level & XP Header
                levelHeader
                
                // MARK: - Quick Stats Cards
                quickStatsCards
                
                // MARK: - Skill Tree Overview
                skillTreeOverview
                
                // MARK: - XP Breakdown Card
                xpBreakdownCard
                
                // MARK: - Danger Zone
                DangerZoneSection(
                    skillManager: skillManager,
                    showResetConfirmation: $showResetConfirmation
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showDetail) {
            if let selectedCard = selectedCard {
                ProgressCardDetailView(card: selectedCard, skillManager: skillManager)
            }
        }
    }
    
    // MARK: - Level Header
    private var levelHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(skillManager.levelEmoji)
                            .font(.largeTitle)
                        Text("Level \(skillManager.currentLevel)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                    }
                    
                    Text(skillManager.levelTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(skillManager.totalXP)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.purple)
                    
                    Text("Total XP")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // XP Progress to Next Level
            VStack(spacing: 8) {
                HStack {
                    Text("Next Level")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(skillManager.xpProgressToNextLevel) / \(skillManager.xpForNextLevel - skillManager.xpForCurrentLevel) XP")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: geometry.size.width * skillManager.levelProgress, height: 8)
                            .animation(.easeInOut(duration: 0.6), value: skillManager.levelProgress)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Quick Stats Cards (2x2 Grid)
    private var quickStatsCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            
            // Skills Overview Card
            ProgressCard(
                title: "Skills",
                value: "\(skillManager.unlockedSkills.count)",
                subtitle: "of \(totalSkillsCount) total",
                icon: "star.fill",
                color: .blue,
                isInteractive: true
            ) {
                selectedCard = .skillsOverview
                showDetail = true
            }
            
            // Next Goal Card
            ProgressCard(
                title: "Next Goal",
                value: "\(skillManager.xpNeededForNextLevel)",
                subtitle: "XP to level up",
                icon: "target",
                color: .green,
                isInteractive: true
            ) {
                selectedCard = .nextGoal
                showDetail = true
            }
            
            // Trees Progress Card
            ProgressCard(
                title: "Trees",
                value: "\(completedTreesCount)/4",
                subtitle: "completed",
                icon: "tree.fill",
                color: .orange,
                isInteractive: true
            ) {
                selectedCard = .treesProgress
                showDetail = true
            }
            
            // Master Skills Card
            ProgressCard(
                title: "Elite",
                value: "\(masterSkillsUnlocked)",
                subtitle: "master skills",
                icon: "crown.fill",
                color: .purple,
                isInteractive: true
            ) {
                selectedCard = .masterSkills
                showDetail = true
            }
        }
    }
    
    // MARK: - Skill Tree Overview
    private var skillTreeOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Skill Trees")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(["pull", "push", "core", "legs"], id: \.self) { treeID in
                    TreeProgressRow(
                        treeID: treeID,
                        skillManager: skillManager
                    )
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - XP Breakdown Card
    private var xpBreakdownCard: some View {
        ProgressCard(
            title: "XP Breakdown",
            value: "\(skillManager.totalXP)",
            subtitle: "tap for details",
            icon: "chart.bar.fill",
            color: .cyan,
            isInteractive: true
        ) {
            selectedCard = .xpBreakdown
            showDetail = true
        }
    }
    
    // MARK: - Computed Properties
    private var totalSkillsCount: Int {
        return allEnhancedSkillTrees.flatMap { tree in
            tree.foundationalSkills + tree.branches.flatMap { $0.skills } + tree.masterSkills
        }.count
    }
    
    private var completedTreesCount: Int {
        return ["pull", "push", "core", "legs"].filter { treeID in
            let progress = skillManager.getTreeProgress(treeID)
            return progress.unlocked == progress.total && progress.total > 0
        }.count
    }
    
    private var masterSkillsUnlocked: Int {
        return allEnhancedSkillTrees.flatMap { $0.masterSkills }
            .filter { skillManager.isUnlocked($0.id) }.count
    }
}

// MARK: - Progress Card
struct ProgressCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let isInteractive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    if isInteractive {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isInteractive)
    }
}

// MARK: - Tree Progress Row
struct TreeProgressRow: View {
    let treeID: String
    @ObservedObject var skillManager: GlobalSkillManager
    
    private var treeInfo: (name: String, emoji: String, color: Color) {
        switch treeID {
        case "pull": return ("Pull", "🆙", .blue)
        case "push": return ("Push", "🙌", .red)
        case "core": return ("Core", "🧱", .orange)
        case "legs": return ("Legs", "🦿", .green)
        default: return ("Unknown", "❓", .gray)
        }
    }
    
    var body: some View {
        let progress = skillManager.getTreeProgress(treeID)
        let info = treeInfo
        let progressPercent = progress.total > 0 ? Double(progress.unlocked) / Double(progress.total) : 0
        
        HStack {
            Text(info.emoji)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(info.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(progress.unlocked)/\(progress.total)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: progressPercent)
                    .progressViewStyle(LinearProgressViewStyle(tint: info.color))
                    .scaleEffect(y: 0.8)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Progress Card Types
enum ProgressCardType {
    case skillsOverview
    case nextGoal
    case treesProgress
    case masterSkills
    case xpBreakdown
}

// MARK: - Card Detail View
struct ProgressCardDetailView: View {
    let card: ProgressCardType
    @ObservedObject var skillManager: GlobalSkillManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    switch card {
                    case .skillsOverview:
                        SkillsOverviewDetail(skillManager: skillManager)
                    case .nextGoal:
                        NextGoalDetail(skillManager: skillManager)
                    case .treesProgress:
                        TreesProgressDetail(skillManager: skillManager)
                    case .masterSkills:
                        MasterSkillsDetail(skillManager: skillManager)
                    case .xpBreakdown:
                        XPBreakdownDetail(skillManager: skillManager)
                    }
                }
                .padding(20)
            }
            .navigationTitle(cardTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var cardTitle: String {
        switch card {
        case .skillsOverview: return "Skills Overview"
        case .nextGoal: return "Next Goal"
        case .treesProgress: return "Tree Progress"
        case .masterSkills: return "Master Skills"
        case .xpBreakdown: return "XP Breakdown"
        }
    }
}

// MARK: - Detail Views
struct SkillsOverviewDetail: View {
    @ObservedObject var skillManager: GlobalSkillManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Skills Breakdown")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                SkillCategoryCard(
                    title: "Foundational Skills",
                    unlocked: foundationalCount,
                    total: totalFoundational,
                    color: .blue,
                    icon: "building.2.fill"
                )
                
                SkillCategoryCard(
                    title: "Branch Skills",
                    unlocked: branchCount,
                    total: totalBranch,
                    color: .green,
                    icon: "leaf.fill"
                )
                
                SkillCategoryCard(
                    title: "Master Skills",
                    unlocked: masterCount,
                    total: totalMaster,
                    color: .purple,
                    icon: "crown.fill"
                )
            }
            
            Spacer()
        }
    }
    
    private var foundationalCount: Int {
        allEnhancedSkillTrees.flatMap { $0.foundationalSkills }
            .filter { skillManager.isUnlocked($0.id) }.count
    }
    
    private var totalFoundational: Int {
        allEnhancedSkillTrees.flatMap { $0.foundationalSkills }.count
    }
    
    private var branchCount: Int {
        allEnhancedSkillTrees.flatMap { $0.branches.flatMap { $0.skills } }
            .filter { skillManager.isUnlocked($0.id) }.count
    }
    
    private var totalBranch: Int {
        allEnhancedSkillTrees.flatMap { $0.branches.flatMap { $0.skills } }.count
    }
    
    private var masterCount: Int {
        allEnhancedSkillTrees.flatMap { $0.masterSkills }
            .filter { skillManager.isUnlocked($0.id) }.count
    }
    
    private var totalMaster: Int {
        allEnhancedSkillTrees.flatMap { $0.masterSkills }.count
    }
}

struct SkillCategoryCard: View {
    let title: String
    let unlocked: Int
    let total: Int
    let color: Color
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(unlocked) of \(total) unlocked")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(total > 0 ? Int((Double(unlocked) / Double(total)) * 100) : 0)%")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct NextGoalDetail: View {
    @ObservedObject var skillManager: GlobalSkillManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Level Up Progress")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                HStack {
                    Text("Current Level")
                    Spacer()
                    Text("\(skillManager.currentLevel)")
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("Current XP")
                    Spacer()
                    Text("\(skillManager.totalXP)")
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("XP Needed")
                    Spacer()
                    Text("\(skillManager.xpNeededForNextLevel)")
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            
            Text("Recommendations")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(skillManager.getNextLevelRecommendations(), id: \.self) { recommendation in
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text(recommendation)
                            .font(.subheadline)
                    }
                }
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            
            Spacer()
        }
    }
}

struct TreesProgressDetail: View {
    @ObservedObject var skillManager: GlobalSkillManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Tree Progress")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ForEach(["pull", "push", "core", "legs"], id: \.self) { treeID in
                    let progress = skillManager.getTreeProgress(treeID)
                    let treeInfo = getTreeInfo(treeID)
                    
                    HStack {
                        Text(treeInfo.emoji)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(treeInfo.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("\(progress.unlocked) of \(progress.total) skills")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(progress.total > 0 ? Int((Double(progress.unlocked) / Double(progress.total)) * 100) : 0)%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(treeInfo.color)
                    }
                    .padding(16)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                }
            }
            
            Spacer()
        }
    }
    
    private func getTreeInfo(_ treeID: String) -> (name: String, emoji: String, color: Color) {
        switch treeID {
        case "pull": return ("Pull Tree", "🆙", .blue)
        case "push": return ("Push Tree", "🙌", .red)
        case "core": return ("Core Tree", "🧱", .orange)
        case "legs": return ("Legs Tree", "🦿", .green)
        default: return ("Unknown", "❓", .gray)
        }
    }
}

struct MasterSkillsDetail: View {
    @ObservedObject var skillManager: GlobalSkillManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Master Skills")
                .font(.title2)
                .fontWeight(.bold)
            
            let allMasterSkills = allEnhancedSkillTrees.flatMap { $0.masterSkills }
            let unlockedMaster = allMasterSkills.filter { skillManager.isUnlocked($0.id) }
            let lockedMaster = allMasterSkills.filter { !skillManager.isUnlocked($0.id) }
            
            if !unlockedMaster.isEmpty {
                Text("Unlocked")
                    .font(.headline)
                    .foregroundColor(.green)
                
                ForEach(unlockedMaster, id: \.id) { skill in
                    MasterSkillCard(skill: skill, isUnlocked: true)
                }
            }
            
            if !lockedMaster.isEmpty {
                Text("Available")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                ForEach(lockedMaster, id: \.id) { skill in
                    MasterSkillCard(skill: skill, isUnlocked: false)
                }
            }
            
            Spacer()
        }
    }
}

struct MasterSkillCard: View {
    let skill: SkillNode
    let isUnlocked: Bool
    
    var body: some View {
        HStack {
            Text(skill.label)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(skill.fullLabel)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Tree: \(skill.tree.capitalized)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: isUnlocked ? "checkmark.circle.fill" : "lock.circle.fill")
                .foregroundColor(isUnlocked ? .green : .orange)
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .opacity(isUnlocked ? 1.0 : 0.7)
    }
}

struct XPBreakdownDetail: View {
    @ObservedObject var skillManager: GlobalSkillManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("XP Breakdown")
                .font(.title2)
                .fontWeight(.bold)
            
            let breakdown = skillManager.getXPBreakdown()
            
            VStack(spacing: 12) {
                XPSourceCard(
                    title: "Skills XP",
                    value: breakdown.skillsXP,
                    color: .blue,
                    icon: "star.fill"
                )
                
                Divider()
                
                XPSourceCard(
                    title: "Total XP",
                    value: breakdown.total,
                    color: .green,
                    icon: "sum"
                )
            }
            
            Spacer()
        }
    }
}

struct XPSourceCard: View {
    let title: String
    let value: Int
    let color: Color
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text("\(value)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}
