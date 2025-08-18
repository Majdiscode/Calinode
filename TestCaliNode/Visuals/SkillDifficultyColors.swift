//
//  SkillDifficultyColors.swift
//  TestCaliNode
//
//  Consistent color scheme based on skill difficulty levels
//

import SwiftUI

// MARK: - Skill Difficulty Levels
enum SkillDifficulty: Int, CaseIterable {
    case easy = 0
    case intermediate = 1
    case advanced = 2
    case elite = 3
    
    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .elite: return "Elite"
        }
    }
    
    var color: Color {
        switch self {
        case .easy: return Color(hex: "#F5DEB3")        // Light sand/wheat (fill)
        case .intermediate: return Color(hex: "#DEB887") // Burlywood/medium sand (fill)
        case .advanced: return Color(hex: "#CD853F")     // Peru/dark sand (fill)
        case .elite: return Color(hex: "#8B4513")        // Saddle brown/darkest (fill)
        }
    }
    
    var outlineColor: Color {
        switch self {
        case .easy: return Color(hex: "#DEB887")        // Burlywood (darker than fill)
        case .intermediate: return Color(hex: "#CD853F") // Peru (darker than fill)
        case .advanced: return Color(hex: "#8B4513")     // Saddle brown (darker than fill)
        case .elite: return Color(hex: "#654321")        // Dark brown (darker than fill)
        }
    }
    
    var description: String {
        switch self {
        case .easy: return "Foundational movements"
        case .intermediate: return "Building strength"
        case .advanced: return "Challenging progressions"
        case .elite: return "Master-level skills"
        }
    }
}

// MARK: - Skill Difficulty Classification
extension SkillNode {
    var difficulty: SkillDifficulty {
        // Classification based on variationLevel and skill patterns
        switch variationLevel {
        case 0:
            return .easy
        case 1:
            return .intermediate
        case 2:
            return .advanced
        case 3...:
            return .elite
        default:
            return .easy
        }
    }
    
    var difficultyColor: Color {
        return difficulty.color
    }
    
    var difficultyOutlineColor: Color {
        return difficulty.outlineColor
    }
}

// MARK: - Enhanced Skill Tree Model Extensions
extension EnhancedSkillTreeModel {
    func getSkillDifficulty(_ skillID: String) -> SkillDifficulty {
        if let skill = allSkills.first(where: { $0.id == skillID }) {
            return skill.difficulty
        }
        return .easy
    }
    
    func getSkillsByDifficulty(_ difficulty: SkillDifficulty) -> [SkillNode] {
        return allSkills.filter { $0.difficulty == difficulty }
    }
}

// MARK: - Updated Skill Circle Component
struct DifficultySkillCircle: View {
    let skill: SkillNode
    let unlocked: Bool
    
    var body: some View {
        Text(skill.label)
            .font(.system(size: 28))
            .frame(width: 70, height: 70)
            .background(
                Circle()
                    .fill(unlocked ? skill.difficultyColor : skill.difficultyColor.opacity(0.3))
            )
            .foregroundColor(.white)
            .overlay(
                Circle()
                    .stroke(skill.difficultyColor, lineWidth: unlocked ? 3 : 1)
                    .opacity(unlocked ? 1.0 : 0.6)
            )
            .shadow(
                color: unlocked ? skill.difficultyColor.opacity(0.4) : .clear,
                radius: unlocked ? 6 : 0,
                x: 0,
                y: 2
            )
            .scaleEffect(unlocked ? 1.0 : 0.9)
            .animation(.spring(response: 0.4), value: unlocked)
    }
}

// MARK: - Difficulty Legend Component
struct SkillDifficultyLegend: View {
    @ObservedObject var skillManager: GlobalSkillManager
    let skillTree: EnhancedSkillTreeModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(SkillDifficulty.allCases, id: \.rawValue) { difficulty in
                    DifficultyLegendItem(
                        difficulty: difficulty,
                        count: getSkillCount(for: difficulty),
                        unlockedCount: getUnlockedCount(for: difficulty)
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .background(Color(UIColor.systemBackground).opacity(0.9))
    }
    
    private func getSkillCount(for difficulty: SkillDifficulty) -> Int {
        return skillTree.getSkillsByDifficulty(difficulty).count
    }
    
    private func getUnlockedCount(for difficulty: SkillDifficulty) -> Int {
        return skillTree.getSkillsByDifficulty(difficulty)
            .filter { skillManager.isUnlocked($0.id) }
            .count
    }
}

struct DifficultyLegendItem: View {
    let difficulty: SkillDifficulty
    let count: Int
    let unlockedCount: Int
    
    var body: some View {
        VStack(spacing: 8) {
            // Color indicator
            Circle()
                .fill(difficulty.color)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
            
            // Difficulty name
            Text(difficulty.displayName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Progress indicator
            if count > 0 {
                Text("\(unlockedCount)/\(count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(difficulty.color.opacity(0.1))
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

// MARK: - Updated Line Connector with Difficulty Colors
struct DifficultyLineConnector: View {
    let from: CGPoint
    let to: CGPoint
    let fromSkill: SkillNode
    let toSkill: SkillNode
    
    var lineColor: Color {
        // Use the higher difficulty color for the connection
        let maxDifficulty = max(fromSkill.difficulty.rawValue, toSkill.difficulty.rawValue)
        return SkillDifficulty(rawValue: maxDifficulty)?.color ?? SkillDifficulty.easy.color
    }
    
    var body: some View {
        Canvas { context, size in
            var path = SwiftUI.Path()
            path.move(to: from)
            path.addLine(to: to)
            context.stroke(path, with: .color(lineColor.opacity(0.6)), lineWidth: 2)
        }
    }
}
