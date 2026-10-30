//
//  AlertPresentable.swift
//  Aura
//

import SwiftUI

@MainActor
protocol AlertPresentable: AnyObject {
    var showAlert: Bool { get set }
    var alertMessage: String { get set }
}

extension AlertPresentable {
    func presentAlert(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}

extension Error {
    var userMessage: String {
        (self as? LocalizedError)?.errorDescription ?? "Что-то пошло не так. Попробуйте ещё раз"
    }
}
