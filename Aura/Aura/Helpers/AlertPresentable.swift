//
//  AlertPresentable.swift
//  Aura
//
//  Created by wamhrm on 31.10.2026.
//

import Foundation

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
        (self as? LocalizedError)?.errorDescription ?? AppLanguage.text("Что-то пошло не так. Попробуйте ещё раз")
    }
}
