//
//  FixedSkillTreeLayoutView.swift
//  TestCaliNode
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EnhancedSkillTreeLayoutView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var skillManager: GlobalSkillManager
    
    let skillTree: EnhancedSkillTreeModel
    
    @State private var prereqMessage: String? = nil
    @State private var showCard = false
    @State private var pendingSkill: SkillNode? = nil
    @State private var selectedBranch: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Minimalist branch selection - less cluttered
            if !skillTree.branches.isEmpty {
                minimalistBranchSelection
                    .background(Color(UIColor.systemBackground))
                    .zIndex(1)
            }
            
            // Clean scrollable content
            ScrollView {
                let contentHeight: CGFloat = 1200 // Fixed reasonable height
                
                ZStack {
                    // Subtle connection lines
                    minimalistConnectorLines()
                    
                    // Skills with better spacing
                    skillNodesView()
                }
                .frame(width: UIScreen.main.bounds.width, height: contentHeight)
                .clipped()
            }
        }
        .overlay(
            // FIXED: Centered overlays for both confirmation and error messages
            Group {
                if showCard, let skill = pendingSkill {
                    // Confirmation card overlay
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
                } else if let message = prereqMessage {
                    // FIXED: Centered error message overlay
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
            }
        )
        .onAppear {
            // ✅ FIXED: Don't override skillManager.allSkills, just ensure this tree's skills are included
            ensureTreeSkillsAreLoaded()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SkillsReset"))) { _ in
            skillManager.resetAllProgress()        }
    }
    
    // MARK: - Fixed: Don't Override All Skills
    private func ensureTreeSkillsAreLoaded() {
        // Just verify that this tree's skills are loaded in the global manager
        let treeSkillIDs = skillTree.allSkills.map(\.id)
        let missingSkills = treeSkillIDs.filter { skillManager.allSkills[$0] == nil }
        
        if !missingSkills.isEmpty {
            print("⚠️ Missing skills in GlobalSkillManager: \(missingSkills)")
            // Force a refresh if skills are missing
            skillManager.forceRefresh()
        }
    }
    
    // MARK: - Minimalist Branch Selection
    private var minimalistBranchSelection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) { // More spacing between buttons
                // Clean "All" button
                Button("All") {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        selectedBranch = nil
                    }
                }
                .buttonStyle(MinimalistBranchButtonStyle(
                    isSelected: selectedBranch == nil,
                    color: .blue
                ))
                
                // Clean individual branch buttons
                ForEach(skillTree.branches, id: \.id) { branch in
                    Button(branch.name) {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            selectedBranch = selectedBranch == branch.id ? nil : branch.id
                        }
                    }
                    .buttonStyle(MinimalistBranchButtonStyle(
                        isSelected: selectedBranch == branch.id,
                        color: Color(hex: branch.color)
                    ))
                }
            }
            .padding(.horizontal, 24) // More padding
            .padding(.vertical, 20)   // More vertical space
        }
        .background(Color(UIColor.systemBackground).opacity(0.98))
    }
    
    // MARK: - Clean Skills Display
    private func skillNodesView() -> some View {
        Group {
            // Foundational skills
            ForEach(skillTree.foundationalSkills) { skill in
                renderMinimalistSkillNode(skill: skill, branchColor: nil)
            }
            
            // Branch skills with conditional visibility
            ForEach(skillTree.branches, id: \.id) { branch in
                if selectedBranch == nil || selectedBranch == branch.id {
                    ForEach(branch.skills) { skill in
                        renderMinimalistSkillNode(skill: skill, branchColor: Color(hex: branch.color))
                    }
                }
            }
            
            // Master skills
            ForEach(skillTree.masterSkills) { skill in
                renderMinimalistSkillNode(skill: skill, branchColor: Color(hex: "#FFD700"))
            }
        }
    }
    
    // MARK: - Minimalist Skill Node
    private func renderMinimalistSkillNode(skill: SkillNode, branchColor: Color?) -> some View {
        guard let pos = skillTree.allPositions[skill.id] else {
            return AnyView(EmptyView())
        }
        
        let isUnlocked = skillManager.isUnlocked(skill.id)
        let canUnlock = skillManager.canUnlock(skill.id)
        
        return AnyView(
            MinimalistSkillCircle(
                label: skill.label,
                unlocked: isUnlocked,
                branchColor: branchColor
            )
            .position(pos)
            .id(skill.id)
            .opacity(selectedBranch == nil || isSkillInSelectedBranch(skill) ? 1.0 : 0.2)
            .scaleEffect(selectedBranch == nil || isSkillInSelectedBranch(skill) ? 1.0 : 0.7)
            .animation(.easeInOut(duration: 0.4), value: selectedBranch)
            .onTapGesture {
                handleSkillTap(skill: skill)
            }
        )
    }
    
    // MARK: - Subtle Connection Lines
    private func minimalistConnectorLines() -> some View {
        ForEach(skillTree.allSkills, id: \.id) { skill in
            ForEach(skill.requires, id: \.self) { reqID in
                if let from = skillTree.allPositions[reqID], let to = skillTree.allPositions[skill.id] {
                    let isVisible = selectedBranch == nil ||
                                   isSkillInSelectedBranch(skill) ||
                                   skillTree.foundationalSkills.contains(where: { $0.id == reqID })
                    
                    MinimalistLineConnector(from: from, to: to)
                        .opacity(isVisible ? 0.6 : 0.1) // Much more subtle
                        .animation(.easeInOut(duration: 0.4), value: selectedBranch)
                }
            }
        }
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
}

// MARK: - NEW: Centered Error Message Component
struct CenteredErrorMessage: View {
    let message: String
    let onDismiss: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var animateCard = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Error icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            
            // Error message
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .lineLimit(nil)
            
            // Dismiss button
            Button(action: {
                withAnimation {
                    animateCard = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onDismiss()
                }
            }) {
                Text("Got it")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(24)
        .frame(maxWidth: 320, minHeight: 200)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
                .shadow(radius: 16)
        )
        .padding(.horizontal, 40)
        .scaleEffect(animateCard ? 1 : 0.9)
        .opacity(animateCard ? 1 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: animateCard)
        .onAppear {
            animateCard = true
            
            // Auto-dismiss after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                if animateCard { // Only dismiss if still showing
                    onDismiss()
                }
            }
        }
        .onTapGesture {
            // Allow tapping anywhere on the card to dismiss
            onDismiss()
        }
    }
}

// MARK: - Minimalist Button Style
struct MinimalistBranchButtonStyle: ButtonStyle {
    let isSelected: Bool
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? color : Color.gray.opacity(0.1))
            )
            .foregroundColor(isSelected ? .white : .primary)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Minimalist Components
struct MinimalistSkillCircle: View {
    let label: String
    let unlocked: Bool
    let branchColor: Color?
    
    var body: some View {
        Text(label)
            .font(.system(size: 28)) // Slightly larger for better visibility
            .frame(width: 70, height: 70) // Bigger circles with more space
            .background(
                Circle()
                    .fill(unlocked ? (branchColor ?? Color(hex: "#0096FF")) : Color.black.opacity(0.8))
            )
            .foregroundColor(.white)
            .overlay(
                Circle()
                    .stroke(branchColor ?? .white, lineWidth: unlocked ? 3 : 1)
                    .opacity(0.8)
            )
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            .scaleEffect(unlocked ? 1.0 : 0.9)
            .animation(.spring(response: 0.4), value: unlocked)
    }
}

// MARK: - Updated Minimalist Line Connector
// Replace the existing MinimalistLineConnector in SkillTreeLayoutView.swift



struct MinimalistLineConnector: View {
    let from: CGPoint
    let to: CGPoint
    
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
            context.stroke(path, with: .color(.white), lineWidth: 4) // Bright white
        }
    }
}
