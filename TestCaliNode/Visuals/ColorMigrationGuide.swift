//
//  ColorMigrationGuide.swift
//  TestCaliNode
//
//  Migration strategy and mapping for gradual transition
//  from legacy color system to new AppColorSystem
//

import SwiftUI

// MARK: - Migration Strategy Documentation
/*
 
 GRADUAL COLOR MIGRATION PLAN
 ============================
 
 This file documents the step-by-step migration from the existing color system
 to the new Electric Gradient theme while maintaining compatibility.
 
 CURRENT COLOR SYSTEM ANALYSIS:
 
 1. AppColors.swift - Main color palette with hex values
    - appPrimary: #192F4D (Prussian blue)
    - appSecondary: #BF9C73 (Lion tan) 
    - skillPrimary: #07DEED (Robin egg blue)
    - skillSecondary: #14A3A1 (Light sea green)
    - appError: #B61624 (Fire brick red)
 
 2. SkillDifficultyColors.swift - Sand/brown color scheme
    - Easy: #F5DEB3 (Light sand)
    - Intermediate: #DEB887 (Burlywood)  
    - Advanced: #CD853F (Peru)
    - Elite: #8B4513 (Saddle brown)
 
 3. ColorExtension.swift - Function-based colors
    - Tree colors: blue, red, orange, green
    - Branch colors: Various hex colors
    - Difficulty: green→yellow→orange→red→purple
    - Progress: red→orange→blue→green
 
 NEW ELECTRIC GRADIENT MAPPING:
 ==============================
 
 Electric Blue (#00F0FF) → Primary actions, main branding
 Blue-Cyan Transition → Secondary actions, info states  
 Blue-Purple Bridge → Intermediate states, transitions
 Vivid Purple → Important highlights, advanced features
 Hot Pink → Accent, CTAs, achievements
 
 MIGRATION PHASES:
 =================
 
 Phase 1: Foundation ✅
 - Create AppColorSystem with dual theme support
 - Legacy theme maps to existing colors
 - Electric theme uses new gradient colors
 
 Phase 2: Tab-by-Tab Migration (Current Phase)
 - Settings Tab (Low risk)
 - Progress Tab (Charts benefit from gradients)
 - About/Support (Simple UI)
 - Workout Tab (Moderate complexity)
 - Skills Tab (Most complex - save for last)
 
 Phase 3: Component Migration
 - Buttons → Electric gradient backgrounds
 - Headers → Subtle gradient tints  
 - Cards → Gradient borders/backgrounds
 - Progress bars → Gradient fills
 - Skill nodes → Gradient based on difficulty
 
 Phase 4: Semantic Color Mapping
 - Success: Keep green but tint toward blue-cyan
 - Warning: Shift orange toward pink tones
 - Error: Keep red but add pink undertones
 - Info: Map to blue-cyan transition color
 - Primary: Electric Blue
 - Secondary: Vivid Purple
 - Accent: Hot Pink
 
 */

// MARK: - Color Migration Utility
class ColorMigrationHelper {
    
    // MARK: - Legacy to Electric Mapping
    static func mapLegacyColor(_ legacyColor: Color) -> Color {
        let colorManager = AppColorManager(useElectricTheme: true)
        let theme = colorManager.theme
        
        // Attempt to identify legacy color and map to electric equivalent
        if legacyColor.isApproximately(Color(hex: "#192F4D")) {      // appPrimary
            return theme.primary
        } else if legacyColor.isApproximately(Color(hex: "#BF9C73")) { // appSecondary
            return theme.tertiary
        } else if legacyColor.isApproximately(Color(hex: "#07DEED")) { // skillPrimary
            return theme.secondary
        } else if legacyColor.isApproximately(Color(hex: "#14A3A1")) { // skillSecondary
            return theme.accent
        } else if legacyColor.isApproximately(Color(hex: "#B61624")) { // appError
            return theme.error
        }
        
        // Difficulty colors mapping
        else if legacyColor.isApproximately(Color(hex: "#F5DEB3")) {   // Easy - light sand
            return theme.success
        } else if legacyColor.isApproximately(Color(hex: "#DEB887")) { // Intermediate - burlywood
            return theme.secondary
        } else if legacyColor.isApproximately(Color(hex: "#CD853F")) { // Advanced - peru
            return theme.primary
        } else if legacyColor.isApproximately(Color(hex: "#8B4513")) { // Elite - saddle brown
            return theme.accent
        }
        
        // Default system colors
        else if legacyColor.isApproximately(Color.blue) {
            return theme.primary
        } else if legacyColor.isApproximately(Color.red) {
            return theme.accent
        } else if legacyColor.isApproximately(Color.orange) {
            return theme.warning
        } else if legacyColor.isApproximately(Color.green) {
            return theme.success
        } else if legacyColor.isApproximately(Color.purple) {
            return theme.tertiary
        }
        
        // Return original if no mapping found
        return legacyColor
    }
    
    // MARK: - Migration Status Tracking
    static var migratedComponents: Set<String> = []
    
    static func markComponentMigrated(_ componentName: String) {
        migratedComponents.insert(componentName)
        print("✅ Migrated component: \(componentName)")
    }
    
    static func isMigrated(_ componentName: String) -> Bool {
        return migratedComponents.contains(componentName)
    }
    
    static var migrationProgress: Double {
        let totalComponents = expectedComponents.count
        let migratedCount = migratedComponents.count
        return totalComponents > 0 ? Double(migratedCount) / Double(totalComponents) : 0.0
    }
    
    // Expected components to migrate
    private static let expectedComponents = [
        "MainTabView", "SkillTreeContainer", "ProgressDashboard", 
        "EnhancedSettingsView", "WorkoutTrackerView", "QuestView",
        "SkillNodeView", "SkillCircleComponent", "StatCard",
        "BranchCard", "HeaderSection", "AboutView"
    ]
}

// MARK: - Compatibility Extensions
extension Color {
    
    // Helper to check if two colors are approximately equal
    func isApproximately(_ other: Color, tolerance: CGFloat = 0.1) -> Bool {
        let thisUIColor = UIColor(self)
        let otherUIColor = UIColor(other)
        
        var thisRed: CGFloat = 0, thisGreen: CGFloat = 0, thisBlue: CGFloat = 0, thisAlpha: CGFloat = 0
        var otherRed: CGFloat = 0, otherGreen: CGFloat = 0, otherBlue: CGFloat = 0, otherAlpha: CGFloat = 0
        
        thisUIColor.getRed(&thisRed, green: &thisGreen, blue: &thisBlue, alpha: &thisAlpha)
        otherUIColor.getRed(&otherRed, green: &otherGreen, blue: &otherBlue, alpha: &otherAlpha)
        
        return abs(thisRed - otherRed) <= tolerance &&
               abs(thisGreen - otherGreen) <= tolerance &&
               abs(thisBlue - otherBlue) <= tolerance &&
               abs(thisAlpha - otherAlpha) <= tolerance
    }
    
    // Gradually transition between legacy and electric colors
    func transitionTo(_ electricColor: Color, progress: CGFloat) -> Color {
        let clampedProgress = max(0, min(1, progress))
        
        let thisUIColor = UIColor(self)
        let electricUIColor = UIColor(electricColor)
        
        var thisRed: CGFloat = 0, thisGreen: CGFloat = 0, thisBlue: CGFloat = 0, thisAlpha: CGFloat = 0
        var electricRed: CGFloat = 0, electricGreen: CGFloat = 0, electricBlue: CGFloat = 0, electricAlpha: CGFloat = 0
        
        thisUIColor.getRed(&thisRed, green: &thisGreen, blue: &thisBlue, alpha: &thisAlpha)
        electricUIColor.getRed(&electricRed, green: &electricGreen, blue: &electricBlue, alpha: &electricAlpha)
        
        let newRed = thisRed + (electricRed - thisRed) * clampedProgress
        let newGreen = thisGreen + (electricGreen - thisGreen) * clampedProgress
        let newBlue = thisBlue + (electricBlue - thisBlue) * clampedProgress
        let newAlpha = thisAlpha + (electricAlpha - thisAlpha) * clampedProgress
        
        return Color(red: newRed, green: newGreen, blue: newBlue, opacity: newAlpha)
    }
}

// MARK: - Migration-Safe Color Accessors
extension AppColorManager {
    
    // Safe color access that respects migration flags
    func safeColor(for component: String, semantic: AppColorSemantic) -> Color {
        if ColorMigrationHelper.isMigrated(component) {
            return semanticColor(semantic)
        } else {
            // Return legacy compatible color
            let legacyManager = AppColorManager(useElectricTheme: false)
            return legacyManager.semanticColor(semantic)
        }
    }
    
    func safeGradient(for component: String, gradientType: AppGradientType) -> LinearGradient {
        if ColorMigrationHelper.isMigrated(component) {
            return gradientFor(gradientType)
        } else {
            // Return simple legacy gradient
            let legacyManager = AppColorManager(useElectricTheme: false)
            return legacyManager.gradientFor(gradientType)
        }
    }
}

// MARK: - Migration Testing Utilities
struct ColorMigrationTestView: View {
    @StateObject private var electricManager = {
        AppColorManager(useElectricTheme: true)
    }()
    @StateObject private var legacyManager = {
        AppColorManager(useElectricTheme: false)
    }()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Color Migration Test")
                .font(.title)
                .fontWeight(.bold)
            
            HStack(spacing: 40) {
                VStack {
                    Text("Legacy Theme")
                        .font(.headline)
                    
                    colorSwatch(legacyManager.theme.primary, "Primary")
                    colorSwatch(legacyManager.theme.secondary, "Secondary")
                    colorSwatch(legacyManager.theme.accent, "Accent")
                    colorSwatch(legacyManager.theme.tertiary, "Tertiary")
                }
                
                VStack {
                    Text("Electric Theme")
                        .font(.headline)
                    
                    colorSwatch(electricManager.theme.primary, "Primary")
                    colorSwatch(electricManager.theme.secondary, "Secondary") 
                    colorSwatch(electricManager.theme.accent, "Accent")
                    colorSwatch(electricManager.theme.tertiary, "Tertiary")
                }
            }
            
            Text("Migration Progress: \(Int(ColorMigrationHelper.migrationProgress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private func colorSwatch(_ color: Color, _ name: String) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 20, height: 20)
            Text(name)
                .font(.caption)
        }
    }
}