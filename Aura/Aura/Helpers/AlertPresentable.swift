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
    var alertBinding: Binding<Bool> {
        binding(\.showAlert)
    }

    func binding(_ keyPath: ReferenceWritableKeyPath<Self, Bool>) -> Binding<Bool> {
        Binding {
            self[keyPath: keyPath]
        } set: { newValue in
            if self[keyPath: keyPath] != newValue {
                self[keyPath: keyPath] = newValue
            }
        }
    }

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
