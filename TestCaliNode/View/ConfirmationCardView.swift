//
//  ConfirmationCardView.swift
//  TestCaliNode
//

import SwiftUI

struct ConfirmationCardView: View {
    let prompt: String
    let confirmAction: () -> Void
    let cancelAction: () -> Void
    let treeID: String?
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var colorManager = AppColorManager(useElectricTheme: true)
    @State private var animateCard = false

    var body: some View {
        VStack(spacing: 24) {
            Text(prompt)
                .font(.system(size: 18, weight: .semibold))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 20) {
                Button(action: {
                    withAnimation {
                        animateCard = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        cancelAction()
                    }
                }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.15))
                        .foregroundColor(.primary)
                        .clipShape(Capsule())
                }

                Button(action: {
                    withAnimation {
                        animateCard = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        confirmAction()
                    }
                }) {
                    Text("Yes")
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(treeID != nil ? colorManager.skillTreeColor(for: treeID!) : Color(hex: "#dfceac"))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(24)
        .frame(maxWidth: 300, minHeight: 220)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
                .shadow(radius: 16)
        )
        .padding(.horizontal)
        .scaleEffect(animateCard ? 1 : 0.9)
        .opacity(animateCard ? 1 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: animateCard)
        .onAppear {
            animateCard = true
        }
    }
}
