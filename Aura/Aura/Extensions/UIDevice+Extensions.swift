//
//  UIDevice+Extensions.swift
//  Aura
//
//  Created by ddorsat on 21.05.2026.
//

import Foundation
import UIKit

extension UIDevice {
    static let isPlus: Bool = {
        guard let screen = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.screen
        else {
            return false
        }

        return screen.nativeBounds.height >= 2796
    }()
}

enum Adaptive {
    static func size<T>(_ base: T, _ plus: T) -> T {
        UIDevice.isPlus ? plus : base
    }
}
