//
//  CompatibilityScore.swift
//  AuraBackend
//
//  Created by wamhrm on 03.11.2026.
//

enum CompatibilityScore {
    static func calculate(userSign: HoroscopeSign, partnerSign: HoroscopeSign) -> Int {
        switch stepsOnZodiacCircle(first: userSign, second: partnerSign) {
            case 0: 75
            case 1: 55
            case 2: 80
            case 3: 45
            case 4: 90
            case 5: 50
            default: 65
        }
    }

    private static func stepsOnZodiacCircle(first: HoroscopeSign, second: HoroscopeSign) -> Int {
        let signs = HoroscopeSign.allCases
        let steps = abs((signs.firstIndex(of: first) ?? 0) - (signs.firstIndex(of: second) ?? 0))
        return min(steps, signs.count - steps)
    }
}
