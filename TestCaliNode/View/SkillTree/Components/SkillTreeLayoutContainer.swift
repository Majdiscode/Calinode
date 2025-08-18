//
//  SkillTreeLayoutContainer.swift
//  TestCaliNode
//
//  Simplified version with difficulty-based colors
//

import SwiftUI

struct SkillTreeLayoutContainer: View {
    @ObservedObject var skillManager: GlobalSkillManager
    let skillTree: EnhancedSkillTreeModel
    
    // State management
    @State private var prereqMessage: String? = nil
    @State private var showCard = false
    @State private var pendingSkill: SkillNode? = nil
    @State private var selectedBranch: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Branch selection bar (existing logic)
            if !skillTree.branches.isEmpty {
                branchSelectionView
            }
            
            // Main skill tree canvas with difficulty colors
            skillTreeCanvas
        }
        .overlay(overlayContent)
        .onAppear {
            ensureTreeSkillsAreLoaded()
        }
    }
    
    // MARK: - Branch Selection View (unchanged)
    private var branchSelectionView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                allBranchButton
                
                ForEach(skillTree.branches, id: \.id) { branch in
                    individualBranchButton(branch: branch)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .background(Color(UIColor.systemBackground).opacity(0.98))
    }
    
    private var allBranchButton: some View {
        Button("All") {
            withAnimation(.easeInOut(duration: 0.4)) {
                selectedBranch = nil
            }
        }
        .font(.system(size: 15, weight: selectedBranch == nil ? .semibold : .medium))
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(selectedBranch == nil ? Color.blue : Color.gray.opacity(0.1))
        )
        .foregroundColor(selectedBranch == nil ? .white : .primary)
    }
    
    private func individualBranchButton(branch: SkillBranch) -> some View {
        Button(branch.name) {
            withAnimation(.easeInOut(duration: 0.4)) {
                selectedBranch = selectedBranch == branch.id ? nil : branch.id
            }
        }
        .font(.system(size: 15, weight: selectedBranch == branch.id ? .semibold : .medium))
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(selectedBranch == branch.id ? Color(hex: branch.color) : Color.gray.opacity(0.1))
        )
        .foregroundColor(selectedBranch == branch.id ? .white : .primary)
    }
    
    // MARK: - Skill Tree Canvas with Difficulty Colors
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
               let toPos = skillTree.allPositions[skillID] {
                
                let isVisible = selectedBranch == nil ||
                isSkillInSelectedBranch(skill) ||
                skillTree.foundationalSkills.contains(where: { $0.id == reqID })
                
                MinimalistLineConnector(from: fromPos, to: toPos)
                    .opacity(isVisible ? 0.6 : 0.1)
                    .animation(.easeInOut(duration: 0.4), value: selectedBranch)
            }
        }
    }
    
    private var skillNodes: some View {
        Group {
            foundationalNodes
            branchNodes
            masterNodes
        }
    }
    
    private var foundationalNodes: some View {
        ForEach(skillTree.foundationalSkills) { skill in
            skillNodeView(skill: skill)
        }
    }
    
    private var branchNodes: some View {
        ForEach(skillTree.branches, id: \.id) { branch in
            Group {
                if selectedBranch == nil || selectedBranch == branch.id {
                    ForEach(branch.skills) { skill in
                        skillNodeView(skill: skill)
                    }
                }
            }
        }
    }
    
    private var masterNodes: some View {
        ForEach(skillTree.masterSkills) { skill in
            skillNodeView(skill: skill)
        }
    }
    
    // MARK: - Updated Skill Node with Uniform Bright Blue Colors
    private func skillNodeView(skill: SkillNode) -> some View {
        Group {
            if let position = skillTree.allPositions[skill.id] {
                let isVisible = selectedBranch == nil || isSkillInSelectedBranch(skill)
                let isUnlocked = skillManager.isUnlocked(skill.id)
                
                // Use uniform bright blue colors for all skills
                let fillColor = Color(hex: "#00BFFF")      // Bright light blue (Deep Sky Blue)
                let outlineColor = Color(hex: "#0080FF")   // Slightly darker bright blue
                
                Text(skill.label)
                    .font(.system(size: 28))
                    .frame(width: 70, height: 70)
                    .background(
                        Circle()
                            .fill(isUnlocked ? fillColor : fillColor.opacity(0.3))
                    )
                    .foregroundColor(.black)
                    .overlay(
                        Circle()
                            .stroke(outlineColor, lineWidth: isUnlocked ? 8 : 6)
                            .opacity(isUnlocked ? 1.0 : 0.8)
                    )
                    .shadow(
                        color: isUnlocked ? outlineColor.opacity(0.4) : .clear,
                        radius: isUnlocked ? 6 : 0,
                        x: 0,
                        y: 2
                    )
                    .scaleEffect(isUnlocked ? 1.0 : 0.9)
                    .position(position)
                    .id(skill.id)
                    .opacity(isVisible ? 1.0 : 0.2)
                    .scaleEffect(isVisible ? 1.0 : 0.7)
                    .animation(.easeInOut(duration: 0.4), value: isVisible)
                    .animation(.spring(response: 0.4), value: isUnlocked)
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
                ConfirmationCardView(
                    prompt: skill.confirmPrompt,
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
    private func isSkillInSelectedBranch(_ skill: SkillNode) -> Bool {
        guard let selectedBranch = selectedBranch else { return true }
        
        if skillTree.foundationalSkills.contains(where: { $0.id == skill.id }) ||
            skillTree.masterSkills.contains(where: { $0.id == skill.id }) {
            return true
        }
        
        return skillTree.branches.first(where: { $0.id == selectedBranch })?.skills.contains(where: { $0.id == skill.id }) == true
    }
    
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

#Preview {
    SkillTreeLayoutContainer(
        skillManager: GlobalSkillManager(),
        skillTree: allEnhancedSkillTrees.pullTree!
    )
    .frame(height: 800)
    .padding()
}
