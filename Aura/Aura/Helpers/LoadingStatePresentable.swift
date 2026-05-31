//
//  LoadingStatePresentable.swift
//  Aura
//

import SwiftUI

@MainActor
protocol LoadingStatePresentable: AnyObject {
    var isServerWakingUp: Bool { get set }
    var showAlert: Bool { get set }
    var alertMessage: String { get set }
}

extension LoadingStatePresentable {
    func presentAlert(_ message: String) {
        alertMessage = message
        showAlert = true
    }

    func withServerWakeUpIndicator(after delay: Duration,
                                   perform operation: () async -> Void) async {
        let wakeUpTask = Task {
            try await Task.sleep(for: delay)
            if !Task.isCancelled {
                withAnimation { self.isServerWakingUp = true }
            }
        }
        
        defer { wakeUpTask.cancel() }
        await operation()

        withAnimation { self.isServerWakingUp = false }
    }
}
