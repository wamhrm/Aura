//
//  AlertPresentable.swift
//  Aura
//
//  Created by wamhrm on 31.10.2026.
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

extension Binding where Value == Bool {
    func removeDuplicates() -> Binding<Bool> {
        Binding {
            wrappedValue
        } set: { newValue in
            guard newValue != wrappedValue else { return }
            wrappedValue = newValue
        }
    }
}
