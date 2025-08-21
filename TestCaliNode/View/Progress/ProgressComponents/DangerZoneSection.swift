//
//  DangerZoneSection.swift
//  TestCaliNode
//
//  Achievement-Free Version - Fixed Reset Method Name
//

import SwiftUI

struct DangerZoneSection: View {
    @ObservedObject var skillManager: GlobalSkillManager
    @Binding var showResetConfirmation: Bool
    
    @State private var showSkillResetConfirmation = false
    @State private var expandedSection: DangerAction? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            sectionHeader
            
            // Danger Actions
            VStack(spacing: 12) {
                DangerActionCard(
                    action: .resetSkills,
                    isExpanded: expandedSection == .resetSkills,
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            expandedSection = expandedSection == .resetSkills ? nil : .resetSkills
                        }
                    },
                    onConfirm: {
                        handleDangerAction(.resetSkills)
                    }
                )
            }
        }
        .padding(24)
        .background(Color.red.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(20)
        .alert("Reset All Progress?", isPresented: $showSkillResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset All", role: .destructive) {
                skillManager.resetAllProgress()  // ← Fixed method name
            }
        } message: {
            Text("This will permanently delete all your skill progress. This action cannot be undone.")
        }
    }
    
    // MARK: - Section Header
    private var sectionHeader: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.red)
            
            Text("Danger Zone")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.red)
            
            Spacer()
            
            Text("⚠️")
                .font(.title3)
        }
    }
    
    // MARK: - Handle Danger Actions
    private func handleDangerAction(_ action: DangerAction) {
        switch action {
        case .resetSkills:
            showSkillResetConfirmation = true
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            expandedSection = nil
        }
    }
}

// MARK: - Danger Action Enum
enum DangerAction: String, CaseIterable {
    case resetSkills = "resetSkills"
    
    var title: String {
        switch self {
        case .resetSkills: return "Reset All Progress"
        }
    }
    
    var description: String {
        switch self {
        case .resetSkills: return "This will permanently delete all your unlocked skills and progress. This action cannot be undone."
        }
    }
    
    var buttonText: String {
        switch self {
        case .resetSkills: return "Reset All Progress"
        }
    }
    
    var color: Color {
        switch self {
        case .resetSkills: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .resetSkills: return "trash.fill"
        }
    }
}

// MARK: - Danger Action Card
struct DangerActionCard: View {
    let action: DangerAction
    let isExpanded: Bool
    let onTap: () -> Void
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible)
            Button(action: onTap) {
                HStack {
                    Image(systemName: action.icon)
                        .font(.title3)
                        .foregroundColor(action.color)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(action.title)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        if !isExpanded {
                            Text("Tap to expand")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.3), value: isExpanded)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                        .padding(.vertical, 8)
                    
                    Text(action.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Button(action: onConfirm) {
                        HStack {
                            Image(systemName: action.icon)
                                .font(.caption)
                            Text(action.buttonText)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(action.color)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
}
