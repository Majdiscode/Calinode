//
//  SkillCircleComponent.swift
//  TestCaliNode
//
//  Reusable Skill Circle Component
//  CREATE this file in: View/SkillTree/Components/SkillCircleComponent.swift
//

import SwiftUI

struct SkillCircleComponent: View {
    let label: String
    let unlocked: Bool
    let branchColor: Color?
    
    var body: some View {
        Text(label)
            .font(.system(size: 28))
            .frame(width: 70, height: 70)
            .background(
                Circle()
                    .fill(unlocked ? (branchColor ?? Color(hex: "#0096FF")) : Color.black)
            )
            .foregroundColor(.white)
            .overlay(
                Circle()
                    .stroke(branchColor ?? .white, lineWidth: unlocked ? 3 : 1)
                    .opacity(0.8)
            )
            .overlay(
                Group {
                    if !unlocked {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 20))
                    }
                }
            )
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            .scaleEffect(unlocked ? 1.0 : 0.9)
            .animation(.spring(response: 0.4), value: unlocked)
    }
}
