//
//  AppColorSystem.swift
//  TestCaliNode
//
//  Global centralized color system with gradient support
//  Migration-ready replacement for existing color files
//

import SwiftUI

// MARK: - Global App Color Theme Protocol
protocol AppColorTheme {
    // Core Brand Colors
    var primary: Color { get }      // Main brand color (Electric Blue #00F0FF)
    var secondary: Color { get }    // Secondary brand (Blue-Cyan transition)  
    var accent: Color { get }       // Accent highlights (Hot Pink)
    var tertiary: Color { get }     // Tertiary support (Vivid Purple)
    
    // UI System Colors
    var background: Color { get }
    var surface: Color { get }
    var surfaceVariant: Color { get }
    var text: Color { get }
    var textSecondary: Color { get }
    var textOnPrimary: Color { get }
    
    // Semantic Colors
    var success: Color { get }
    var warning: Color { get }
    var error: Color { get }
    var info: Color { get }
    
    // Interactive Colors
    var buttonPrimary: Color { get }
    var buttonSecondary: Color { get }
    var buttonTertiary: Color { get }
    
    // Skill System Colors
    var skillUnlocked: Color { get }
    var skillLocked: Color { get }
    var skillMaster: Color { get }
    
    // Gradient Support
    var primaryGradient: LinearGradient { get }
    var accentGradient: LinearGradient { get }
    var buttonGradient: LinearGradient { get }
    var backgroundGradient: LinearGradient { get }
    var skillGradient: LinearGradient { get }
}

// MARK: - Electric Gradient Theme (New Design System)
struct ElectricGradientTheme: AppColorTheme {
    // Core Brand Colors (Electric Blue → Violet → Hot Pink)
    var primary: Color { Color(red: 0.0, green: 0.941, blue: 1.0) }        // Electric Blue #00F0FF
    var secondary: Color { Color(red: 0.3, green: 0.7, blue: 1.0) }        // Bright Blue-Cyan
    var accent: Color { Color(red: 1.0, green: 0.1, blue: 0.6) }           // Hot Pink
    var tertiary: Color { Color(red: 0.7, green: 0.2, blue: 0.95) }        // Vivid Purple
    
    // UI System Colors
    var background: Color { Color(UIColor.systemBackground) }
    var surface: Color { Color(UIColor.secondarySystemBackground) }
    var surfaceVariant: Color { Color(UIColor.tertiarySystemBackground) }
    var text: Color { Color.primary }
    var textSecondary: Color { Color.secondary }
    var textOnPrimary: Color { Color.white }
    
    // Semantic Colors (Adapted to gradient theme)
    var success: Color { Color(red: 0.2, green: 0.8, blue: 0.6) }          // Teal-green
    var warning: Color { Color(red: 1.0, green: 0.6, blue: 0.2) }          // Orange-pink
    var error: Color { Color(red: 1.0, green: 0.3, blue: 0.4) }            // Pink-red
    var info: Color { secondary }                                           // Blue-cyan
    
    // Interactive Colors
    var buttonPrimary: Color { primary }
    var buttonSecondary: Color { tertiary }
    var buttonTertiary: Color { secondary }
    
    // Skill System Colors
    var skillUnlocked: Color { primary }
    var skillLocked: Color { Color.gray }
    var skillMaster: Color { accent }
    
    // Gradient Definitions
    var primaryGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [primary, secondary]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var accentGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [tertiary, accent]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var buttonGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                primary,                                    // Electric Blue #00F0FF
                Color(red: 0.3, green: 0.7, blue: 1.0),   // Bright Blue-Cyan
                Color(red: 0.5, green: 0.4, blue: 1.0),   // Blue-Purple bridge
                tertiary,                                   // Vivid Purple
                accent                                      // Hot Pink
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                primary.opacity(0.08),
                secondary.opacity(0.06),
                Color(red: 0.5, green: 0.4, blue: 1.0).opacity(0.04),
                tertiary.opacity(0.06),
                accent.opacity(0.08)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var skillGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [primary, tertiary, accent]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Legacy Compatibility Theme (Maps to existing colors)
struct LegacyCompatibilityTheme: AppColorTheme {
    // Map existing AppColors to new system
    var primary: Color { Color(hex: "#192F4D") }            // Prussian blue (existing appPrimary)
    var secondary: Color { Color(hex: "#BF9C73") }          // Lion tan (existing appSecondary)
    var accent: Color { Color(hex: "#07DEED") }             // Robin egg blue (existing skillPrimary)
    var tertiary: Color { Color(hex: "#14A3A1") }           // Light sea green (existing skillSecondary)
    
    var background: Color { Color(UIColor.systemBackground) }
    var surface: Color { Color(UIColor.secondarySystemBackground) }
    var surfaceVariant: Color { Color(UIColor.tertiarySystemBackground) }
    var text: Color { Color.primary }
    var textSecondary: Color { Color.secondary }
    var textOnPrimary: Color { Color.white }
    
    var success: Color { accent }
    var warning: Color { Color(hex: "#B61624") }            // Fire brick red (existing appError)
    var error: Color { Color(hex: "#B61624") }
    var info: Color { primary }
    
    var buttonPrimary: Color { primary }
    var buttonSecondary: Color { secondary }
    var buttonTertiary: Color { accent }
    
    var skillUnlocked: Color { accent }
    var skillLocked: Color { Color.gray }
    var skillMaster: Color { secondary }
    
    // Simple gradients for legacy compatibility
    var primaryGradient: LinearGradient {
        LinearGradient(colors: [primary, primary.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
    }
    
    var accentGradient: LinearGradient {
        LinearGradient(colors: [accent, accent.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    var buttonGradient: LinearGradient {
        LinearGradient(colors: [primary, secondary], startPoint: .leading, endPoint: .trailing)
    }
    
    var backgroundGradient: LinearGradient {
        LinearGradient(colors: [primary.opacity(0.05), secondary.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    var skillGradient: LinearGradient {
        LinearGradient(colors: [accent, tertiary], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Global Color Manager
class AppColorManager: ObservableObject {
    @Published private var currentTheme: AppColorTheme
    @Published var isElectricThemeEnabled: Bool = false {
        didSet {
            currentTheme = isElectricThemeEnabled ? ElectricGradientTheme() : LegacyCompatibilityTheme()
        }
    }
    
    init(useElectricTheme: Bool = false) {
        self.isElectricThemeEnabled = useElectricTheme
        self.currentTheme = useElectricTheme ? ElectricGradientTheme() : LegacyCompatibilityTheme()
    }
    
    // MARK: - Theme Access
    var theme: AppColorTheme {
        return currentTheme
    }
    
    // MARK: - Migration Helper Methods
    func enableElectricTheme() {
        isElectricThemeEnabled = true
    }
    
    func disableElectricTheme() {
        isElectricThemeEnabled = false
    }
    
    func toggleTheme() {
        isElectricThemeEnabled.toggle()
    }
}

// MARK: - Component-Specific Color Categories
extension AppColorManager {
    
    // MARK: - Skill Tree Colors
    func skillTreeColor(for treeID: String) -> Color {
        switch treeID {
        case "pull": return theme.primary
        case "push": return theme.tertiary
        case "core": return theme.secondary
        case "legs": return theme.accent
        default: return theme.primary
        }
    }
    
    func skillTreeGradient(for treeID: String) -> LinearGradient {
        switch treeID {
        case "pull": return theme.primaryGradient
        case "push": return theme.accentGradient
        case "core": return theme.backgroundGradient
        case "legs": return theme.skillGradient
        default: return theme.primaryGradient
        }
    }
    
    // MARK: - Difficulty-Based Colors (Enhanced)
    func difficultyColor(for level: Int) -> Color {
        switch level {
        case 0: return theme.success
        case 1: return theme.secondary
        case 2: return theme.primary
        case 3: return theme.tertiary
        case 4...: return theme.accent
        default: return theme.text.opacity(0.5)
        }
    }
    
    func difficultyGradient(for level: Int) -> LinearGradient {
        let baseColor = difficultyColor(for: level)
        return LinearGradient(
            colors: [baseColor, baseColor.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Progress Colors
    func progressColor(for percentage: Double) -> Color {
        switch percentage {
        case 0..<0.25: return theme.error
        case 0.25..<0.5: return theme.warning
        case 0.5..<0.75: return theme.info
        case 0.75..<1.0: return theme.success
        default: return theme.accent // Complete!
        }
    }
    
    func progressGradient(for percentage: Double) -> LinearGradient {
        let baseColor = progressColor(for: percentage)
        return LinearGradient(
            colors: [baseColor, baseColor.opacity(0.6)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Convenience Extensions
extension AppColorManager {
    
    // Pre-defined gradient styles for common UI elements
    var headerGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                theme.primary.opacity(0.9),
                theme.secondary.opacity(0.8),
                theme.tertiary.opacity(0.7)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var cardGradient: LinearGradient {
        theme.backgroundGradient
    }
    
    var vibrantButtonGradient: LinearGradient {
        theme.buttonGradient
    }
    
    var subtleBackgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                theme.primary.opacity(0.02),
                theme.secondary.opacity(0.015),
                theme.tertiary.opacity(0.01),
                theme.accent.opacity(0.02)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - View Extensions for Easy Usage
extension View {
    func appThemeColor(_ semantic: AppColorSemantic, colorManager: AppColorManager) -> some View {
        self.foregroundColor(colorManager.semanticColor(semantic))
    }
    
    func appThemeBackground(_ semantic: AppColorSemantic, colorManager: AppColorManager) -> some View {
        self.background(colorManager.semanticColor(semantic))
    }
    
    func appThemeGradient(_ gradientType: AppGradientType, colorManager: AppColorManager) -> some View {
        self.background(colorManager.gradientFor(gradientType))
    }
}

// MARK: - Semantic Color Helper
extension AppColorManager {
    func semanticColor(_ semantic: AppColorSemantic) -> Color {
        switch semantic {
        case .primaryText: return theme.text
        case .secondaryText: return theme.textSecondary
        case .primaryButton: return theme.buttonPrimary
        case .secondaryButton: return theme.buttonSecondary
        case .accentButton: return theme.accent
        case .cardBackground: return theme.surface
        case .mainBackground: return theme.background
        case .success: return theme.success
        case .warning: return theme.warning
        case .error: return theme.error
        case .skillUnlocked: return theme.skillUnlocked
        case .skillLocked: return theme.skillLocked
        case .skillMaster: return theme.skillMaster
        }
    }
    
    func gradientFor(_ gradientType: AppGradientType) -> LinearGradient {
        switch gradientType {
        case .primaryButton: return theme.buttonGradient
        case .accentButton: return theme.accentGradient
        case .cardBackground: return theme.backgroundGradient
        case .screenBackground: return LinearGradient(
            gradient: Gradient(colors: [
                theme.primary.opacity(0.025),
                theme.secondary.opacity(0.02),
                theme.tertiary.opacity(0.015),
                theme.accent.opacity(0.025)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        case .header: return headerGradient
        case .interactive: return theme.buttonGradient
        case .skill: return theme.skillGradient
        }
    }
}

// MARK: - Enums for Semantic Usage
enum AppColorSemantic {
    case primaryText, secondaryText
    case primaryButton, secondaryButton, accentButton
    case cardBackground, mainBackground
    case success, warning, error
    case skillUnlocked, skillLocked, skillMaster
}

enum AppGradientType {
    case primaryButton, accentButton
    case cardBackground, screenBackground
    case header, interactive, skill
}