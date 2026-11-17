//
//  CompatibilityScore.swift
//  AuraBackend
//
//  Created by wamhrm on 03.11.2026.
//

enum CompatibilityScore {
    static func calculate(userSign: HoroscopeSign, partnerSign: HoroscopeSign) -> Int {
        switch stepsOnZodiacCircle(first: userSign, second: partnerSign) {
            case 0: 58
            case 1: 45
            case 2: 68
            case 3: 30
            case 4: 82
            case 5: 38
            default: 34
        }
    }

    static func barRange(score: Int) -> ClosedRange<Int> {
        switch score {
            case ...40: 1...4
            case 41...60: 1...6
            case 61...80: 1...8
            default: 1...10
        }
    }

    private static func stepsOnZodiacCircle(first: HoroscopeSign, second: HoroscopeSign) -> Int {
        let signs = HoroscopeSign.allCases
        let steps = abs((signs.firstIndex(of: first) ?? 0) - (signs.firstIndex(of: second) ?? 0))
        return min(steps, signs.count - steps)
    }
}
