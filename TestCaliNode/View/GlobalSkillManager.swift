//
//  GlobalSkillManager.swift
//  TestCaliNode
//
//  Cleaned Version - All Achievement References Removed - Method Names Fixed
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class GlobalSkillManager: ObservableObject {
    @Published var unlockedSkills: Set<String> = []
    @Published var allSkills: [String: SkillNode] = [:]
    
    internal let db = Firestore.firestore()
    
    init() {
        loadAllSkillsFromTrees()
        loadUserProgress()
    }
    
    // MARK: - Load All Skills from Enhanced Trees
    private func loadAllSkillsFromTrees() {
        var skillsDict: [String: SkillNode] = [:]
        
        // Load all skills from all enhanced trees
        for tree in allEnhancedSkillTrees {
            // Add foundational skills
            for skill in tree.foundationalSkills {
                skillsDict[skill.id] = skill
            }
            
            // Add branch skills
            for branch in tree.branches {
                for skill in branch.skills {
                    skillsDict[skill.id] = skill
                }
            }
            
            // Add master skills
            for skill in tree.masterSkills {
                skillsDict[skill.id] = skill
            }
        }
        
        // Also load from original trees if any exist
        for tree in allSkillTrees {
            for skill in tree.skills {
                skillsDict[skill.id] = skill
            }
        }
        
        DispatchQueue.main.async {
            self.allSkills = skillsDict
            print("✅ Loaded \(skillsDict.count) total skills from all trees")
            self.printSkillCounts()
        }
    }
    
    // MARK: - Debug Helper
    private func printSkillCounts() {
        let treeCounts = ["pull", "push", "core", "legs"].map { treeID in
            let count = allSkills.values.filter { $0.tree == treeID }.count
            return "\(treeID): \(count)"
        }
        print("🔍 Skills per tree: \(treeCounts.joined(separator: ", "))")
    }
    
    // MARK: - Skill Management
    
    func canUnlock(_ skillID: String) -> Bool {
        guard let skill = allSkills[skillID] else { return false }
        guard !unlockedSkills.contains(skillID) else { return true }
        
        return skill.requires.allSatisfy { unlockedSkills.contains($0) }
    }
    
    func unlock(_ skillID: String) {
        guard canUnlock(skillID) else { return }
        unlockedSkills.insert(skillID)
        
        saveProgress(skillID)
        
        print("🔓 Unlocked skill: \(skillID)")
    }
    
    func isUnlocked(_ skillID: String) -> Bool {
        return unlockedSkills.contains(skillID)
    }
    
    func getUnmetRequirements(for skillID: String) -> [String] {
        guard let skill = allSkills[skillID] else { return [] }
        return skill.requires.filter { !unlockedSkills.contains($0) }
    }
    
    func getRequirementNames(for skillID: String) -> [String] {
        let unmetIDs = getUnmetRequirements(for: skillID)
        return unmetIDs.compactMap { id in
            allSkills[id]?.fullLabel.components(separatedBy: " (").first
        }
    }
    
    // MARK: - Progress Analytics
    
    func getTreeProgress(_ treeID: String) -> (unlocked: Int, total: Int) {
        let treeSkills = allSkills.values.filter { skill in
            return skill.tree == treeID
        }
        
        let unlockedCount = treeSkills.filter { isUnlocked($0.id) }.count
        return (unlocked: unlockedCount, total: treeSkills.count)
    }
    
    var completionPercentage: Double {
        let totalSkills = allSkills.count
        guard totalSkills > 0 else { return 0 }
        return Double(unlockedSkills.count) / Double(totalSkills)
    }
    
    var globalLevel: Int {
        return unlockedSkills.count
    }
    
    // MARK: - XP System (Skill-Based Only)
    
    var totalXP: Int {
        // Base XP per skill
        let baseXP = unlockedSkills.count * 50
        
        // Bonus XP for skill types
        let foundationalBonus = foundationalSkillsUnlocked * 25
        let branchBonus = branchSkillsUnlocked * 50
        let masterBonus = masterSkillsUnlocked * 100
        
        return baseXP + foundationalBonus + branchBonus + masterBonus
    }
    
    var currentLevel: Int {
        return min(Int(sqrt(Double(totalXP) / 100)), 50)
    }
    
    var levelTitle: String {
        switch currentLevel {
        case 0: return "Beginner"
        case 1...5: return "Novice"
        case 6...15: return "Intermediate"
        case 16...30: return "Advanced"
        case 31...50: return "Expert"
        default: return "Master"
        }
    }
    
    var levelEmoji: String {
        switch currentLevel {
        case 0: return "🌱"
        case 1...5: return "🥉"
        case 6...15: return "🥈"
        case 16...30: return "🥇"
        case 31...50: return "💎"
        default: return "👑"
        }
    }
    
    var xpForCurrentLevel: Int {
        return currentLevel * currentLevel * 100
    }
    
    var xpForNextLevel: Int {
        return (currentLevel + 1) * (currentLevel + 1) * 100
    }
    
    var xpProgressToNextLevel: Int {
        return totalXP - xpForCurrentLevel
    }
    
    var xpNeededForNextLevel: Int {
        return xpForNextLevel - totalXP
    }
    
    var levelProgress: Double {
        let currentLevelXP = xpForCurrentLevel
        let nextLevelXP = xpForNextLevel
        let progressXP = totalXP - currentLevelXP
        let totalProgressNeeded = nextLevelXP - currentLevelXP
        
        guard totalProgressNeeded > 0 else { return 1.0 }
        return Double(progressXP) / Double(totalProgressNeeded)
    }
    
    // MARK: - XP Breakdown (Skills Only)
    
    func getXPBreakdown() -> (skillsXP: Int, total: Int) {
        let skillsXP = totalXP
        return (skillsXP: skillsXP, total: skillsXP)
    }
    
    func getNextLevelRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if foundationalSkillsUnlocked < totalFoundationalSkills {
            recommendations.append("Focus on foundational skills for steady progress")
        }
        
        if let weakestTree = getWeakestTree() {
            recommendations.append("Train \(weakestTree) skills to balance your development")
        }
        
        if availableMasterSkills > 0 {
            recommendations.append("Master skills available - unlock for massive XP bonus!")
        }
        
        if recommendations.isEmpty {
            recommendations.append("Keep training consistently to reach the next level")
        }
        
        return recommendations
    }
    
    // MARK: - Skill Type Counts
    
    private var foundationalSkillsUnlocked: Int {
        let foundationalSkills = allEnhancedSkillTrees.flatMap { $0.foundationalSkills }
        return foundationalSkills.filter { isUnlocked($0.id) }.count
    }
    
    private var totalFoundationalSkills: Int {
        return allEnhancedSkillTrees.flatMap { $0.foundationalSkills }.count
    }
    
    private var branchSkillsUnlocked: Int {
        let branchSkills = allEnhancedSkillTrees.flatMap { $0.branches.flatMap { $0.skills } }
        return branchSkills.filter { isUnlocked($0.id) }.count
    }
    
    private var masterSkillsUnlocked: Int {
        let masterSkills = allEnhancedSkillTrees.flatMap { $0.masterSkills }
        return masterSkills.filter { isUnlocked($0.id) }.count
    }
    
    private var availableMasterSkills: Int {
        let masterSkills = allEnhancedSkillTrees.flatMap { $0.masterSkills }
        return masterSkills.filter { !isUnlocked($0.id) && canUnlock($0.id) }.count
    }
    
    private func getWeakestTree() -> String? {
        let treeProgresses = ["pull", "push", "core", "legs"].map { treeID -> (id: String, progress: Double) in
            let progress = getTreeProgress(treeID)
            let percentage = progress.total > 0 ? Double(progress.unlocked) / Double(progress.total) : 0
            return (id: treeID, progress: percentage)
        }
        
        return treeProgresses.min(by: { $0.progress < $1.progress })?.id
    }
    
    // MARK: - Data Persistence
    
    private func saveProgress(_ skillID: String) {
        guard let user = Auth.auth().currentUser else {
            saveToUserDefaults()
            return
        }
        
        let userRef = db.collection("users").document(user.uid)
        let unlockedArray = Array(unlockedSkills)
        
        userRef.setData([
            "unlockedSkills": unlockedArray,
            "lastUpdated": Timestamp()
        ], merge: true) { error in
            if let error = error {
                print("❌ Error saving progress: \(error.localizedDescription)")
                self.saveToUserDefaults() // Fallback
            } else {
                print("✅ Progress saved to Firebase")
            }
        }
    }
    
    private func saveToUserDefaults() {
        let unlockedArray = Array(unlockedSkills)
        UserDefaults.standard.set(unlockedArray, forKey: "unlockedSkills")
        print("💾 Progress saved to UserDefaults")
    }
    
    private func loadUserProgress() {
        guard let user = Auth.auth().currentUser else {
            loadFromUserDefaults()
            return
        }
        
        let userRef = db.collection("users").document(user.uid)
        userRef.getDocument { document, error in
            if let error = error {
                print("❌ Error loading progress: \(error.localizedDescription)")
                self.loadFromUserDefaults()
                return
            }
            
            if let document = document, document.exists,
               let data = document.data(),
               let unlockedArray = data["unlockedSkills"] as? [String] {
                DispatchQueue.main.async {
                    self.unlockedSkills = Set(unlockedArray)
                    print("✅ Loaded progress from Firebase: \(unlockedArray.count) skills")
                }
            } else {
                self.loadFromUserDefaults()
            }
        }
    }
    
    private func loadFromUserDefaults() {
        if let unlockedArray = UserDefaults.standard.array(forKey: "unlockedSkills") as? [String] {
            DispatchQueue.main.async {
                self.unlockedSkills = Set(unlockedArray)
                print("📱 Loaded progress from UserDefaults: \(unlockedArray.count) skills")
            }
        }
    }
    
    func forceRefresh() {
        loadAllSkillsFromTrees()
        loadUserProgress()
    }
    
    // MARK: - Reset Functionality (Fixed Method Name)
    
    func resetAllProgress() {  // ← This matches what DangerZoneSection expects
        unlockedSkills.removeAll()
        
        // Clear Firebase
        if let user = Auth.auth().currentUser {
            db.collection("users").document(user.uid).delete()
        }
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "unlockedSkills")
        
        print("🔄 All progress reset")
    }
    
    func resetTree(_ treeID: String) {
        let treeSkillIDs = allSkills.values.filter { $0.tree == treeID }.map(\.id)
        
        for skillID in treeSkillIDs {
            unlockedSkills.remove(skillID)
        }
        
        // Update Firebase
        if let user = Auth.auth().currentUser {
            let userRef = db.collection("users").document(user.uid)
            let unlockedArray = Array(unlockedSkills)
            userRef.setData(["unlockedSkills": unlockedArray], merge: true)
        }
        
        // Update UserDefaults
        saveToUserDefaults()
        
        print("🔄 Reset tree: \(treeID)")
    }
}
