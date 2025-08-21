//
//  ProfileRow.swift
//  TestCaliNode
//
//  Updated to use XP system - 2024
//

import SwiftUI

struct ProfileRow: View {
    @ObservedObject var skillManager: GlobalSkillManager
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(skillManager.levelEmoji)
                        .font(.title2)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Calisthenics Athlete")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Level \(skillManager.currentLevel) \(skillManager.levelTitle) • \(skillManager.totalXP) XP")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ProgressView(value: skillManager.levelProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 1.5)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
