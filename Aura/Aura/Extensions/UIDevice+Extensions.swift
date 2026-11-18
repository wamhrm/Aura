//
//  UIDevice+Extensions.swift
//  Aura
//
//  Created by wamhrm on 21.05.2026.
//

import UIKit

fileprivate enum ScreenSizeClass {
    case base, air, plus
}

struct Adaptive {
    static func size<T>(_ base: T, _ air: T, _ plus: T) -> T {
        switch UIDevice.screenSizeClass {
            case .base: base
            case .air: air
            case .plus: plus
        }
    }
}

extension UIDevice {
    fileprivate static let screenSizeClass: ScreenSizeClass = {
        guard let screen = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.screen
        else {
            return .base
        }

        let bounds = screen.nativeBounds
        let longSide = max(bounds.width, bounds.height)
        let shortSide = min(bounds.width, bounds.height)

        if longSide >= 2770, shortSide >= 1284 {
            return .plus
        }

        if longSide >= 2730 {
            return .air
        }

        return .base
    }()
}
