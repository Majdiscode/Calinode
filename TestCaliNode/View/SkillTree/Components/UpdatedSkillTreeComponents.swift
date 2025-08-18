//
//  UpdatedSkillTreeComponents.swift
//  TestCaliNode
//
//  Replace your existing skill tree rendering components with these
//

import SwiftUI

// MARK: - Updated Skill Tree Layout Container
struct UpdatedSkillTreeLayoutContainer: View {
    @ObservedObject var skillManager: GlobalSkillManager
    let skillTree: EnhancedSkillTreeModel
    
    // State management
    @State private var prereqMessage: String? = nil
    @State private var showCard = false
    @State private var pendingSkill: SkillNode? = nil
    @State private var selectedDifficulty: SkillDifficulty? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Difficulty filter bar
            difficultyFilterView
            
            // Main skill tree canvas
            skillTreeCanvas
        }
        .overlay(overlayContent)
        .onAppear {
            ensureTreeSkillsAreLoaded()
        }
    }
    
    // MARK: - Difficulty Filter View
    private var difficultyFilterView: some View {
        VStack(spacing: 12) {
            // Tree info header
            treeInfoHeader
            
            // Difficulty legend/filter
            SkillDifficultyLegend(skillManager: skillManager, skillTree: skillTree)
                .padding(.vertical, 8)
        }
        .background(Color(UIColor.systemBackground).opacity(0.95))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var treeInfoHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(skillTree.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(skillManager.getTreeProgress(skillTree.id).unlocked)/\(skillManager.getTreeProgress(skillTree.id).total) skills unlocked")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Overall tree progress
            let progress = skillManager.getTreeProgress(skillTree.id)
            let percentage = progress.total > 0 ? Double(progress.unlocked) / Double(progress.total) : 0
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(percentage * 100))%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(percentage == 1.0 ? .green : .blue)
                
                ProgressView(value: percentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: percentage == 1.0 ? .green : .blue))
                    .frame(width: 80)
                    .scaleEffect(y: 1.5)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
    
    // MARK: - Skill Tree Canvas
    private var skillTreeCanvas: some View {
        ScrollView {
            ZStack {
                connectionLines
                skillNodes
            }
            .frame(width: UIScreen.main.bounds.width, height: 1200)
            .clipped()
        }
    }
    
    private var connectionLines: some View {
        ForEach(skillTree.allSkills, id: \.id) { skill in
            ForEach(skill.requires, id: \.self) { reqID in
                connectionLine(from: reqID, to: skill.id, skill: skill)
            }
        }
    }
    
    private func connectionLine(from reqID: String, to skillID: String, skill: SkillNode) -> some View {
        Group {
            if let fromPos = skillTree.allPositions[reqID],
               let toPos = skillTree.allPositions[skillID],
               let fromSkill = skillTree.allSkills.first(where: { $0.id == reqID }) {
                
                let isVisible = selectedDifficulty == nil ||
                               skill.difficulty == selectedDifficulty ||
                               fromSkill.difficulty == selectedDifficulty
                
                DifficultyLineConnector(
                    from: fromPos,
                    to: toPos,
                    fromSkill: fromSkill,
                    toSkill: skill
                )
                .opacity(isVisible ? 0.8 : 0.2)
                .animation(.easeInOut(duration: 0.4), value: selectedDifficulty)
            }
        }
    }
    
    private var skillNodes: some View {
        ForEach(skillTree.allSkills, id: \.id) { skill in
            skillNodeView(skill: skill)
        }
    }
    
    private func skillNodeView(skill: SkillNode) -> some View {
        Group {
            if let position = skillTree.allPositions[skill.id] {
                let isVisible = selectedDifficulty == nil || skill.difficulty == selectedDifficulty
                let isUnlocked = skillManager.isUnlocked(skill.id)
                
                DifficultySkillCircle(skill: skill, unlocked: isUnlocked)
                    .position(position)
                    .id(skill.id)
                    .opacity(isVisible ? 1.0 : 0.3)
                    .scaleEffect(isVisible ? 1.0 : 0.8)
                    .animation(.easeInOut(duration: 0.4), value: isVisible)
                    .onTapGesture {
                        handleSkillTap(skill: skill)
                    }
            }
        }
    }
    
    // MARK: - Overlay Content
    private var overlayContent: some View {
        Group {
            if showCard, let skill = pendingSkill {
                confirmationOverlay(skill: skill)
            } else if let message = prereqMessage {
                errorOverlay(message: message)
            }
        }
    }
    
    private func confirmationOverlay(skill: SkillNode) -> some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .overlay(
                EnhancedConfirmationCard(
                    skill: skill,
                    confirmAction: {
                        skillManager.unlock(skill.id)
                        showCard = false
                    },
                    cancelAction: {
                        showCard = false
                    }
                )
            )
            .zIndex(10)
    }
    
    private func errorOverlay(message: String) -> some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .overlay(
                CenteredErrorMessage(
                    message: message,
                    onDismiss: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            prereqMessage = nil
                        }
                    }
                )
            )
            .zIndex(9)
    }
    
    // MARK: - Helper Functions
    private func handleSkillTap(skill: SkillNode) {
        guard !skillManager.isUnlocked(skill.id) else { return }
        
        if skillManager.canUnlock(skill.id) {
            pendingSkill = skill
            showCard = true
        } else {
            let requirementNames = skillManager.getRequirementNames(for: skill.id)
            let skillName = skill.fullLabel.components(separatedBy: " (").first!
            prereqMessage = "To unlock \(skillName), you must first unlock: \(requirementNames.joined(separator: " and "))"
        }
    }
    
    private func ensureTreeSkillsAreLoaded() {
        let treeSkillIDs = skillTree.allSkills.map(\.id)
        let missingSkills = treeSkillIDs.filter { skillManager.allSkills[$0] == nil }
        
        if !missingSkills.isEmpty {
            print("⚠️ Missing skills in GlobalSkillManager: \(missingSkills)")
            skillManager.forceRefresh()
        }
    }
}

// MARK: - Enhanced Confirmation Card with Difficulty Styling
struct EnhancedConfirmationCard: View {
    let skill: SkillNode
    let confirmAction: () -> Void
    let cancelAction: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var animateCard = false

    var body: some View {
        VStack(spacing: 24) {
            // Skill preview with difficulty styling
            VStack(spacing: 12) {
                DifficultySkillCircle(skill: skill, unlocked: false)
                    .scaleEffect(1.2)
                
                VStack(spacing: 8) {
                    Text(skill.fullLabel.components(separatedBy: " (").first ?? skill.fullLabel)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    // Difficulty badge
                    HStack(spacing: 8) {
                        Circle()
                            .fill(skill.difficultyColor)
                            .frame(width: 12, height: 12)
                        
                        Text(skill.difficulty.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(skill.difficultyColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(skill.difficultyColor.opacity(0.1))
                    )
                }
            }
            
            Text(skill.confirmPrompt)
                .font(.system(size: 16, weight: .medium))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 20) {
                Button(action: {
                    withAnimation {
                        animateCard = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        cancelAction()
                    }
                }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.15))
                        .foregroundColor(.primary)
                        .clipShape(Capsule())
                }

                Button(action: {
                    withAnimation {
                        animateCard = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        confirmAction()
                    }
                }) {
                    Text("Unlock!")
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(skill.difficultyColor)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(24)
        .frame(maxWidth: 320, minHeight: 280)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
                .shadow(radius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(skill.difficultyColor.opacity(0.3), lineWidth: 2)
        )
        .padding(.horizontal)
        .scaleEffect(animateCard ? 1 : 0.9)
        .opacity(animateCard ? 1 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: animateCard)
        .onAppear {
            animateCard = true
        }
    }
}

// MARK: - Difficulty Filter Buttons (Optional Enhancement)
struct DifficultyFilterBar: View {
    @Binding var selectedDifficulty: SkillDifficulty?
    let skillTree: EnhancedSkillTreeModel
    @ObservedObject var skillManager: GlobalSkillManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All skills button
                Button("All") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedDifficulty = nil
                    }
                }
                .buttonStyle(DifficultyFilterButtonStyle(
                    isSelected: selectedDifficulty == nil,
                    color: .gray
                ))
                
                // Individual difficulty buttons
                ForEach(SkillDifficulty.allCases, id: \.rawValue) { difficulty in
                    let skillsInDifficulty = skillTree.getSkillsByDifficulty(difficulty)
                    
                    if !skillsInDifficulty.isEmpty {
                        Button(difficulty.displayName) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedDifficulty = selectedDifficulty == difficulty ? nil : difficulty
                            }
                        }
                        .buttonStyle(DifficultyFilterButtonStyle(
                            isSelected: selectedDifficulty == difficulty,
                            color: difficulty.color
                        ))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
}

struct DifficultyFilterButtonStyle: ButtonStyle {
    let isSelected: Bool
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color : Color.gray.opacity(0.1))
            )
            .foregroundColor(isSelected ? .white : .primary)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
