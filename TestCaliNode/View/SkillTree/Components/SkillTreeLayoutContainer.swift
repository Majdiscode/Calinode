//
//  SkillTreeLayoutContainer.swift
//  TestCaliNode
//
//  Simplified version with difficulty-based colors
//

import SwiftUI

struct SkillTreeLayoutContainer: View {
    @ObservedObject var skillManager: GlobalSkillManager
    @EnvironmentObject var colorManager: AppColorManager
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
                .fill(selectedBranch == nil ? 
                      colorManager.skillTreeGradient(for: skillTree.id) : 
                      LinearGradient(colors: [Color.gray.opacity(0.1)], startPoint: .leading, endPoint: .trailing))
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
                .fill(selectedBranch == branch.id ? 
                      LinearGradient(
                          colors: [colorManager.skillTreeColor(for: skillTree.id).opacity(0.8), 
                                  colorManager.skillTreeColor(for: skillTree.id)],
                          startPoint: .leading,
                          endPoint: .trailing
                      ) : 
                      LinearGradient(colors: [Color.gray.opacity(0.1)], startPoint: .leading, endPoint: .trailing))
        )
        .foregroundColor(selectedBranch == branch.id ? .white : .primary)
    }
    
    // MARK: - Skill Tree Canvas with Dynamic Size
    private var skillTreeCanvas: some View {
        ScrollView {
            ZStack {
                connectionLines
                skillNodes
            }
            .frame(width: UIScreen.main.bounds.width, height: calculateCanvasHeight())
            .clipped()
        }
    }
    
    // MARK: - Standardized Canvas Height Calculation for Consistency
    private func calculateCanvasHeight() -> CGFloat {
        guard !skillTree.allPositions.isEmpty else { return 1200 } // Consistent fallback
        
        // Find the min and max Y positions from all skills
        let yPositions = skillTree.allPositions.values.map { $0.y }
        let minY = yPositions.min() ?? 0
        let maxY = yPositions.max() ?? 600
        let contentHeight = maxY - minY
        
        // Standardized padding calculation for consistent tree sizes
        // Ensure all trees have similar proportional spacing regardless of their Y range
        let standardTopPadding: CGFloat = 120
        let standardBottomPadding: CGFloat = 200
        
        // Minimum canvas height to ensure consistency across trees
        let calculatedHeight = contentHeight + standardTopPadding + standardBottomPadding
        let minimumHeight: CGFloat = 1200 // Ensure all trees have at least this height for consistency
        
        return max(calculatedHeight, minimumHeight)
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
                
                // Use standardized metrics for consistent positioning
                let metrics = treeMetrics
                let standardTopPadding: CGFloat = 120
                let adjustedFromPos = CGPoint(x: fromPos.x, y: fromPos.y - metrics.minY + standardTopPadding)
                let adjustedToPos = CGPoint(x: toPos.x, y: toPos.y - metrics.minY + standardTopPadding)
                
                let prereqSkill = skillTree.allSkills.first(where: { $0.id == reqID })
                let fromVisible = prereqSkill.map { isSkillInSelectedBranch($0) } ?? false
                let toVisible = isSkillInSelectedBranch(skill)
                let isVisible = selectedBranch == nil || (fromVisible && toVisible)

                EnhancedLineConnector(
                    from: adjustedFromPos, 
                    to: adjustedToPos, 
                    color: colorManager.skillTreeColor(for: skillTree.id)
                )
                    .opacity(isVisible ? 0.6 : 0.0)
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
    
    // MARK: - Computed Properties for Future-Proof Gradient System
    private var treeMetrics: (minY: CGFloat, maxY: CGFloat, canvasHeight: CGFloat) {
        let yPositions = skillTree.allPositions.values.map { $0.y }
        let minY = yPositions.min() ?? 0
        let maxY = yPositions.max() ?? 600
        let canvasHeight = calculateCanvasHeight()
        return (minY, maxY, canvasHeight)
    }
    
    // MARK: - Skill Node with Future-Proof Miami Gradient System
    private func skillNodeView(skill: SkillNode) -> some View {
        Group {
            if let position = skillTree.allPositions[skill.id] {
                let isVisible = selectedBranch == nil || isSkillInSelectedBranch(skill)
                let isUnlocked = skillManager.isUnlocked(skill.id)
                let metrics = treeMetrics
                
                // Standardized position adjustment for tree size consistency
                let standardTopPadding: CGFloat = 120
                let adjustedPosition = CGPoint(x: position.x, y: position.y - metrics.minY + standardTopPadding)
                
                // Future-proof gradient calculation - normalizes any skill position range to 0-1
                let yRange = metrics.maxY - metrics.minY
                let normalizedY = yRange > 0 ? (position.y - metrics.minY) / yRange : 0
                let depthColor = colorManager.skillColorByDepth(for: skillTree.id, yPosition: normalizedY * metrics.canvasHeight, canvasHeight: metrics.canvasHeight)
                
                Text(skill.label)
                    .font(.system(size: 28))
                    .frame(width: 70, height: 70)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: isUnlocked ? 
                                        [depthColor, depthColor.opacity(0.7)] :
                                        [depthColor.opacity(0.6), depthColor.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .foregroundColor(isUnlocked ? .white : .primary)
                    .overlay(
                        Circle()
                            .stroke(depthColor, lineWidth: isUnlocked ? 4 : 3)
                            .opacity(isUnlocked ? 1.0 : 0.8)
                    )
                    .shadow(
                        color: isUnlocked ? depthColor.opacity(0.4) : .clear,
                        radius: isUnlocked ? 8 : 0,
                        x: 0,
                        y: isUnlocked ? 4 : 0
                    )
                    .scaleEffect(isUnlocked ? 1.0 : 0.9)
                    .position(adjustedPosition)
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

// MARK: - Enhanced Line Connector with Color Support
struct EnhancedLineConnector: View {
    let from: CGPoint
    let to: CGPoint
    let color: Color
    
    private let nodeRadius: CGFloat = 35 // Half of the 70pt circle size
    
    var body: some View {
        Canvas { context, size in
            // Calculate the direction vector
            let dx = to.x - from.x
            let dy = to.y - from.y
            let distance = sqrt(dx * dx + dy * dy)
            
            // Normalize the direction vector
            let unitX = dx / distance
            let unitY = dy / distance
            
            // Calculate connection points at circle edges
            let startPoint = CGPoint(
                x: from.x + unitX * nodeRadius,
                y: from.y + unitY * nodeRadius
            )
            let endPoint = CGPoint(
                x: to.x - unitX * nodeRadius,
                y: to.y - unitY * nodeRadius
            )
            
            var path = SwiftUI.Path()
            path.move(to: startPoint)
            path.addLine(to: endPoint)
            context.stroke(path, with: .color(color), lineWidth: 4) // Thicker connection lines
        }
    }
}
