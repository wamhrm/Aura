//
//  LoadingStatePresentable.swift
//  Aura
//

import SwiftUI

@MainActor
protocol LoadingStatePresentable: AnyObject {
    var showAlert: Bool { get set }
    var alertMessage: String { get set }
}

extension LoadingStatePresentable {
    func presentAlert(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}
