//
//  ErrorHandling.swift
//  TestCaliNode
//
//  Fixed Version - Updated Method Names
//

import Foundation
import SwiftUI

// MARK: - App Error Types

enum AppError: LocalizedError {
    case networkUnavailable
    case dataCorrupted
    case authenticationRequired
    case skillNotFound(String)
    case firebaseError(Error)
    case unknownError(Error)
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection. Please check your network and try again."
        case .dataCorrupted:
            return "Your data seems corrupted. Please try restarting the app."
        case .authenticationRequired:
            return "Please sign in to save your progress."
        case .skillNotFound(let skillID):
            return "Skill '\(skillID)' not found. Please restart the app."
        case .firebaseError(let error):
            return "Server error: \(error.localizedDescription)"
        case .unknownError(let error):
            return "Something went wrong: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .dataCorrupted:
            return "Try restarting the app or resetting your data."
        case .authenticationRequired:
            return "Sign in to continue saving your progress."
        case .skillNotFound:
            return "Restart the app to reload the latest data."
        case .firebaseError, .unknownError:
            return "If this continues, please contact support."
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .networkUnavailable, .authenticationRequired:
            return .warning
        case .dataCorrupted, .skillNotFound:
            return .error
        case .firebaseError, .unknownError:
            return .critical
        }
    }
}

enum ErrorSeverity {
    case info
    case warning
    case error
    case critical
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .critical: return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        case .critical: return "exclamationmark.octagon"
        }
    }
}

// MARK: - Error Handler Service

class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published var currentError: AppError?
    @Published var showingError = false
    
    private var errorHistory: [ErrorEntry] = []
    private let maxHistorySize = 50
    
    private init() {}
    
    func handle(_ error: Error, context: String = "") {
        let appError = convertToAppError(error)
        logError(appError, context: context)
        
        DispatchQueue.main.async {
            self.currentError = appError
            self.showingError = true
        }
    }
    
    func handleSilently(_ error: Error, context: String = "") {
        let appError = convertToAppError(error)
        logError(appError, context: context)
        // Don't show UI, just log
    }
    
    func dismissError() {
        currentError = nil
        showingError = false
    }
    
    private func convertToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        // Convert Firebase errors
        if error.localizedDescription.contains("network") {
            return .networkUnavailable
        }
        
        if error.localizedDescription.contains("auth") {
            return .authenticationRequired
        }
        
        // Default to unknown error
        return .unknownError(error)
    }
    
    private func logError(_ error: AppError, context: String) {
        let entry = ErrorEntry(
            error: error,
            context: context,
            timestamp: Date()
        )
        
        errorHistory.append(entry)
        
        // Keep history manageable
        if errorHistory.count > maxHistorySize {
            errorHistory.removeFirst()
        }
        
        // Console logging
        print("❌ [\(error.severity)] \(context): \(error.localizedDescription ?? "Unknown error")")
        
        // In production, you might send to analytics
        #if !DEBUG
        // Analytics.track("error_occurred", properties: [
        //     "error_type": String(describing: error),
        //     "context": context,
        //     "severity": String(describing: error.severity)
        // ])
        #endif
    }
    
    // MARK: - Error History for Debugging
    
    func getRecentErrors() -> [ErrorEntry] {
        return Array(errorHistory.suffix(10))
    }
    
    func clearErrorHistory() {
        errorHistory.removeAll()
    }
}

struct ErrorEntry: Identifiable {
    let id = UUID()
    let error: AppError
    let context: String
    let timestamp: Date
}

// MARK: - Error Display Views

struct ErrorBanner: View {
    let error: AppError
    let onDismiss: () -> Void
    let onRetry: (() -> Void)?
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: error.severity.icon)
                .font(.title3)
                .foregroundColor(error.severity.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if let onRetry = onRetry {
                    Button("Retry", action: onRetry)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(error.severity.color)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(error.severity.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(error.severity.color.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(isVisible ? 1 : 0.9)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            isVisible = true
            
            // Auto-dismiss non-critical errors after 5 seconds
            if error.severity != .critical {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    if isVisible {
                        onDismiss()
                    }
                }
            }
        }
    }
}

struct ErrorOverlay: ViewModifier {
    @ObservedObject private var errorHandler = ErrorHandler.shared
    let onRetry: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .overlay(
                VStack {
                    if errorHandler.showingError, let error = errorHandler.currentError {
                        Spacer()
                        
                        ErrorBanner(
                            error: error,
                            onDismiss: {
                                errorHandler.dismissError()
                            },
                            onRetry: onRetry
                        )
                        .padding(.horizontal, 16)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: errorHandler.showingError)
            )
    }
}

extension View {
    func errorHandling(onRetry: (() -> Void)? = nil) -> some View {
        modifier(ErrorOverlay(onRetry: onRetry))
    }
}

// MARK: - Enhanced Manager Extensions with Error Handling

extension GlobalSkillManager {
    
    func unlockSafely(_ skillID: String) {
        do {
            // Validate skill exists
            guard allSkills[skillID] != nil else {
                throw AppError.skillNotFound(skillID)
            }
            
            // Original unlock logic
            unlock(skillID)
            
        } catch {
            ErrorHandler.shared.handle(error, context: "Unlocking skill \(skillID)")
        }
    }
    
    func resetAllProgressSafely() {  // ← Fixed method name
        do {
            resetAllProgress()  // ← Fixed method name
        } catch {
            ErrorHandler.shared.handle(error, context: "Resetting all progress")
        }
    }
}

extension WorkoutManager {
    
    func finishWorkoutSafely() {
        do {
            finishWorkout()
        } catch {
            ErrorHandler.shared.handle(error, context: "Finishing workout")
        }
    }
    
    func createTemplateSafely(name: String, exercises: [WorkoutExercise]) {
        do {
            guard !name.isEmpty else {
                throw AppError.dataCorrupted
            }
            
            // Template functionality removed in simplified workout tracker
            print("Template creation not available in current implementation")
            
        } catch {
            ErrorHandler.shared.handle(error, context: "Creating workout template")
        }
    }
}

// MARK: - Error Debug Panel

struct ErrorDebugPanel: View {
    @ObservedObject private var errorHandler = ErrorHandler.shared
    
    var body: some View {
        NavigationView {
            List {
                Section("Recent Errors") {
                    ForEach(errorHandler.getRecentErrors()) { entry in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: entry.error.severity.icon)
                                    .foregroundColor(entry.error.severity.color)
                                
                                Text(entry.context)
                                    .font(.headline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Text(entry.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(entry.error.localizedDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if let suggestion = entry.error.recoverySuggestion {
                                Text("💡 \(suggestion)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    if errorHandler.getRecentErrors().isEmpty {
                        Text("No recent errors")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                
                Section("Actions") {
                    Button("Test Network Error") {
                        ErrorHandler.shared.handle(AppError.networkUnavailable, context: "Test")
                    }
                    
                    Button("Test Auth Error") {
                        ErrorHandler.shared.handle(AppError.authenticationRequired, context: "Test")
                    }
                    
                    Button("Clear Error History") {
                        errorHandler.clearErrorHistory()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Error Log")
            .navigationBarItems(trailing: Button("Done") {
                // Dismiss
            })
        }
    }
}

// MARK: - Retry Logic Helper

struct RetryOperation<T> {
    let maxAttempts: Int
    let delay: TimeInterval
    let operation: () async throws -> T
    
    init(maxAttempts: Int = 3, delay: TimeInterval = 1.0, operation: @escaping () async throws -> T) {
        self.maxAttempts = maxAttempts
        self.delay = delay
        self.operation = operation
    }
    
    func execute() async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                if attempt < maxAttempts {
                    print("🔄 Retry attempt \(attempt) failed, retrying in \(delay)s...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? AppError.unknownError(NSError(domain: "RetryFailed", code: -1))
    }
}

// MARK: - Usage Examples

struct SafeOperationExamples: View {
    @ObservedObject var skillManager: GlobalSkillManager
    
    var body: some View {
        VStack {
            // Example 1: Safe skill unlock with retry
            Button("Unlock Skill (Safe)") {
                skillManager.unlockSafely("deadHang")
            }
            
            // Example 2: View with error handling
            Text("This view has error handling")
                .errorHandling {
                    // Retry logic
                    print("Retrying operation...")
                }
        }
    }
}
