//
//  CompatibilityScore.swift
//  AuraBackend
//
//  Created by wamhrm on 03.11.2026.
//

// The percent comes from the two zodiac signs, so the same pair always gets the same result. AI only explains it.
enum CompatibilityScore {
    static func calculate(userSign: HoroscopeSign, partnerSign: HoroscopeSign) -> Int {
        switch stepsOnZodiacCircle(from: userSign, to: partnerSign) {
            case 0: 75
            case 1: 55
            case 2: 80
            case 3: 45
            case 4: 90
            case 5: 50
            default: 65
        }
    }

    private static func stepsOnZodiacCircle(from first: HoroscopeSign, to second: HoroscopeSign) -> Int {
        let signs = HoroscopeSign.allCases
        let steps = abs((signs.firstIndex(of: first) ?? 0) - (signs.firstIndex(of: second) ?? 0))
        return min(steps, signs.count - steps)
    }
}
