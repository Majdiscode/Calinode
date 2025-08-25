//
//  ProfileRow.swift
//  TestCaliNode
//
//  Migrated to Electric Gradient Color System
//  Updated with AppColorSystem integration
//

import SwiftUI

struct ProfileRow: View {
    @ObservedObject var skillManager: GlobalSkillManager
    var colorManager: AppColorManager
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(colorManager.theme.primary.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(skillManager.levelEmoji)
                        .font(.title2)
                )
                .background(
                    Circle()
                        .stroke(colorManager.headerGradient, lineWidth: 2)
                        .frame(width: 54, height: 54)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Calisthenics Athlete")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorManager.theme.text)
                
                Text("Level \(skillManager.currentLevel) \(skillManager.levelTitle) • \(skillManager.totalXP) XP")
                    .font(.subheadline)
                    .foregroundColor(colorManager.theme.textSecondary)
                
                // Custom gradient progress bar
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    // Gradient progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorManager.vibrantButtonGradient)
                        .frame(width: max(0, CGFloat(skillManager.levelProgress) * 200), height: 6)
                        .animation(.easeInOut(duration: 0.3), value: skillManager.levelProgress)
                }
                .scaleEffect(y: 1.5)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
