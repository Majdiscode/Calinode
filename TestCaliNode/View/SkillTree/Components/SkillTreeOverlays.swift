//
//  SkillTreeOverlays.swift
//  TestCaliNode
//
//  FIXED - Removed ambiguous opacity usage
//

import SwiftUI

struct SkillTreeOverlays: ViewModifier {
    let showCard: Bool
    let pendingSkill: SkillNode?
    let prereqMessage: String?
    let onConfirm: () -> Void
    let onCancel: () -> Void
    let onDismissError: () -> Void
    @ObservedObject var skillManager: GlobalSkillManager
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if showCard, let skill = pendingSkill {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .overlay(
                                ConfirmationCardView(
                                    prompt: skill.confirmPrompt,
                                    confirmAction: onConfirm,
                                    cancelAction: onCancel,
                                    treeID: skill.tree
                                )
                            )
                            .zIndex(10)
                    } else if let message = prereqMessage {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .overlay(
                                SimpleErrorMessage(
                                    message: message,
                                    onDismiss: onDismissError
                                )
                            )
                            .zIndex(9)
                    }
                }
            )
    }
}

// MARK: - Simple Error Message (to avoid conflicts)
struct SimpleErrorMessage: View {
    let message: String
    let onDismiss: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var animateCard = false
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .lineLimit(nil)
            
            Button(action: {
                withAnimation {
                    animateCard = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onDismiss()
                }
            }) {
                Text("Got it")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(24)
        .frame(maxWidth: 320, minHeight: 200)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
                .shadow(radius: 16)
        )
        .padding(.horizontal, 40)
        .scaleEffect(animateCard ? 1 : 0.9)
        .opacity(animateCard ? 1 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: animateCard)
        .onAppear {
            animateCard = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                if animateCard {
                    onDismiss()
                }
            }
        }
        .onTapGesture {
            onDismiss()
        }
    }
}

// MARK: - View Extension
extension View {
    func skillTreeOverlays(
        showCard: Bool,
        pendingSkill: SkillNode?,
        prereqMessage: String?,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        onDismissError: @escaping () -> Void,
        skillManager: GlobalSkillManager
    ) -> some View {
        modifier(SkillTreeOverlays(
            showCard: showCard,
            pendingSkill: pendingSkill,
            prereqMessage: prereqMessage,
            onConfirm: onConfirm,
            onCancel: onCancel,
            onDismissError: onDismissError,
            skillManager: skillManager
        ))
    }
}
