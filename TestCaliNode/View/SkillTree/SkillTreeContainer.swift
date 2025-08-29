//
//  SkillTreeContainer.swift
//  TestCaliNode
//
//  FIXED VERSION - Smooth scrolling between all trees
//

import SwiftUI

struct SkillTreeContainer: View {
    @ObservedObject var skillManager: GlobalSkillManager
    @EnvironmentObject var colorManager: AppColorManager
    @State private var selectedTreeIndex = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with tree selection and progress
            headerSection
            
            // Main content area with TabView - FIXED SCROLLING
            TabView(selection: $selectedTreeIndex) {
                ForEach(Array(allEnhancedSkillTrees.enumerated()), id: \.offset) { index, tree in
                    SkillTreeLayoutContainer(
                        skillManager: skillManager,
                        skillTree: tree
                    )
                    .tag(index)
                    .clipped() // Ensure content doesn't overflow
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never)) // Remove index dots for cleaner look
            .animation(.easeInOut(duration: 0.6), value: selectedTreeIndex) // Slower animation
            .gesture(
                DragGesture()
                    .onEnded { value in
                        // Enhanced drag gesture for smoother transitions - slower threshold
                        let threshold: CGFloat = 30
                        if value.translation.width > threshold && selectedTreeIndex > 0 {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                selectedTreeIndex -= 1
                            }
                        } else if value.translation.width < -threshold && selectedTreeIndex < allEnhancedSkillTrees.count - 1 {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                selectedTreeIndex += 1
                            }
                        }
                    }
            )
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 6) { // Reduced from 12
            // Current tree info card - Smaller
            if selectedTreeIndex < allEnhancedSkillTrees.count {
                let tree = allEnhancedSkillTrees[selectedTreeIndex]
                let metadata = treeMetadata.first { $0.id == tree.id }
                
                // Redesigned progress card - text left, bar right
                HStack(spacing: 16) {
                    // Left side - Text content
                    VStack(alignment: .leading, spacing: 4) {
                        let progress = skillManager.getTreeProgress(tree.id)
                        let progressPercentage = progress.total > 0 ? Double(progress.unlocked) / Double(progress.total) : 0
                        
                        Text("Skills unlocked")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text("\(progress.unlocked)/\(progress.total)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    // Right side - Progress bar
                    VStack(spacing: 6) {
                        let progress = skillManager.getTreeProgress(tree.id)
                        let progressPercentage = progress.total > 0 ? Double(progress.unlocked) / Double(progress.total) : 0
                        
                        Text("\(Int(progressPercentage * 100))%")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .frame(width: 100, height: 8)
                            .background(Color.gray.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        progressPercentage == 1.0 ? 
                                        LinearGradient(
                                            colors: [colorManager.theme.success, colorManager.theme.success.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ) :
                                        colorManager.skillTreeGradient(for: tree.id)
                                    )
                                    .frame(width: 100 * progressPercentage, height: 8)
                                    .animation(.easeInOut(duration: 0.3), value: progressPercentage),
                                alignment: .leading
                            )
                    }
                }
                .padding(20) // Increased padding for larger card
                .background(
                    // High contrast background with subtle gradient
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(colorManager.skillTreeGradient(for: tree.id).opacity(0.05))
                        )
                )
                .overlay(
                    // Enhanced border for better visibility
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(colorManager.skillTreeColor(for: tree.id).opacity(0.3), lineWidth: 1)
                )
                .shadow(
                    color: colorManager.skillTreeColor(for: tree.id).opacity(0.15),
                    radius: 8,
                    x: 0,
                    y: 4
                )
                .animation(.easeInOut(duration: 0.6), value: selectedTreeIndex)
            }
            
            // Tree navigation dots - Smaller
            HStack(spacing: 8) { // Reduced from 12
                ForEach(0..<allEnhancedSkillTrees.count, id: \.self) { index in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.6)) { // Updated duration
                            selectedTreeIndex = index
                        }
                    }) {
                        let tree = allEnhancedSkillTrees[index]
                        let metadata = treeMetadata.first { $0.id == tree.id }
                        
                        VStack(spacing: 4) {
                            Text(metadata?.emoji ?? "🌟")
                                .font(selectedTreeIndex == index ? .title2 : .title3)
                                .scaleEffect(selectedTreeIndex == index ? 1.1 : 1.0)
                            
                            Text(tree.name)
                                .font(.caption)
                                .fontWeight(selectedTreeIndex == index ? .semibold : .medium)
                                .foregroundColor(selectedTreeIndex == index ? .white : .primary)
                        }
                        .padding(.vertical, 4) // Reduced from 8
                        .padding(.horizontal, 8) // Reduced from 12
                        .background(
                            RoundedRectangle(cornerRadius: 12) // UI design system standard for buttons
                                .fill(selectedTreeIndex == index ? 
                                      colorManager.skillTreeGradient(for: tree.id) : 
                                      LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12) // UI design system standard for buttons
                                .stroke(selectedTreeIndex == index ? 
                                       colorManager.skillTreeColor(for: tree.id) : 
                                       Color.clear, lineWidth: 2) // 2pt weight per UI design
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .animation(.easeInOut(duration: 0.2), value: selectedTreeIndex)
                }
            }
            .padding(.horizontal, 16) // Reduced from 20
        }
        .padding(.horizontal, 24) // Following UI design system (24pt margins)
        .padding(.top, 32) // Generous vertical spacing as per UI doc
        .background(Color(UIColor.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1) // Smaller shadow
    }
}
