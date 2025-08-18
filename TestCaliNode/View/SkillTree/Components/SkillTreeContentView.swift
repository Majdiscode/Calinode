//
//  SkillTreeContentView.swift
//  TestCaliNode
//
//  Main Content View - handles TabView
//  CREATE this file in: View/SkillTree/Components/SkillTreeContentView.swift
//

import SwiftUI

struct SkillTreeContentView: View {
    let selectedTreeIndex: Int
    @ObservedObject var skillManager: GlobalSkillManager
    
    var body: some View {
        TabView(selection: .constant(selectedTreeIndex)) {
            ForEach(Array(allEnhancedSkillTrees.enumerated()), id: \.offset) { index, tree in
                UpdatedSkillTreeLayoutContainer(
                    skillManager: skillManager,
                    skillTree: tree
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .never))
    }
}
