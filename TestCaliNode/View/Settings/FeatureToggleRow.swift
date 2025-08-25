//
//  FeatureToggleRow.swift
//  TestCaliNode
//
//  Migrated to Electric Gradient Color System
//  Updated with AppColorSystem integration
//

import SwiftUI

struct FeatureToggleRow: View {
    let flag: FeatureFlag
    let title: String
    let description: String
    var colorManager: AppColorManager
    @ObservedObject private var featureFlags = FeatureFlagService.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(colorManager.theme.text)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(colorManager.theme.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Toggle("", isOn: .init(
                get: { featureFlags.isEnabled(flag) },
                set: { enabled in
                    featureFlags.setFlag(flag, enabled: enabled)
                    print("🚩 \(title) \(enabled ? "enabled" : "disabled")")
                }
            ))
            .tint(colorManager.theme.accent)
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorManager.cardGradient.opacity(0.3))
                .opacity(featureFlags.isEnabled(flag) ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3), value: featureFlags.isEnabled(flag))
        )
    }
}
