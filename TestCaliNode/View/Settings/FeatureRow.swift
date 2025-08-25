//
//  FeatureRow.swift
//  TestCaliNode
//
//  Migrated to Electric Gradient Color System
//  Updated with AppColorSystem integration
//

import SwiftUI

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    var colorManager: AppColorManager? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(colorManager?.theme.primary ?? .blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(colorManager?.theme.text ?? Color.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(colorManager?.theme.textSecondary ?? .secondary)
            }
            
            Spacer()
        }
    }
}
