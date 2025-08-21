//
//  SkillTreeContainer.swift
//  TestCaliNode
//
//  FIXED VERSION - Smooth scrolling between all trees
//

import SwiftUI

struct SkillTreeContainer: View {
    @ObservedObject var skillManager: GlobalSkillManager
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
                
                HStack {
                    Text(metadata?.emoji ?? "🌟")
                        .font(.system(size: 20)) // Reduced from 32
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tree.name)
                            .font(.headline) // Reduced from title2
                            .fontWeight(.semibold)
                        
                        Text(metadata?.description ?? "")
                            .font(.caption2) // Reduced from caption
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Progress indicator - smaller
                    VStack(alignment: .trailing, spacing: 2) {
                        let progress = skillManager.getTreeProgress(tree.id)
                        let progressPercentage = progress.total > 0 ? Double(progress.unlocked) / Double(progress.total) : 0
                        
                        Text("\(progress.unlocked)/\(progress.total)")
                            .font(.caption2) // Reduced from caption
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        ProgressView(value: progressPercentage)
                            .progressViewStyle(LinearProgressViewStyle(tint: progressPercentage == 1.0 ? .green : .blue))
                            .frame(width: 40, height: 4) // Smaller
                    }
                }
                .padding(10) // Reduced from 16
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8) // Reduced from 12
                .animation(.easeInOut(duration: 0.6), value: selectedTreeIndex) // Updated duration
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
                        
                        VStack(spacing: 2) { // Reduced from 4
                            Text(metadata?.emoji ?? "🌟")
                                .font(selectedTreeIndex == index ? .body : .caption) // Smaller
                                .scaleEffect(selectedTreeIndex == index ? 1.1 : 1.0) // Reduced from 1.2
                            
                            Text(tree.name.prefix(4))
                                .font(.caption2) // Smaller
                                .fontWeight(selectedTreeIndex == index ? .medium : .regular)
                                .foregroundColor(selectedTreeIndex == index ? .primary : .secondary)
                        }
                        .padding(.vertical, 4) // Reduced from 8
                        .padding(.horizontal, 8) // Reduced from 12
                        .background(
                            RoundedRectangle(cornerRadius: 6) // Reduced from 8
                                .fill(selectedTreeIndex == index ? Color.blue.opacity(0.1) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6) // Reduced from 8
                                .stroke(selectedTreeIndex == index ? Color.blue : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .animation(.easeInOut(duration: 0.2), value: selectedTreeIndex)
                }
            }
            .padding(.horizontal, 16) // Reduced from 20
        }
        .padding(.horizontal, 16) // Reduced from 20
        .padding(.top, 6) // Reduced from 10
        .background(Color(UIColor.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1) // Smaller shadow
    }
}
