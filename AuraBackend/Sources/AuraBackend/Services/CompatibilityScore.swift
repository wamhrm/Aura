//
//  CompatibilityScore.swift
//  AuraBackend
//
//  Created by wamhrm on 03.11.2026.
//

// The percent comes from a fixed table, so the same answers always give the same result. AI only explains it.
enum CompatibilityScore {
    static func calculate(user: User, partner: CompatibilityTestRequest) -> Int {
        conflictPoints(user.conflictStyle ?? "", partner.partnerConflictStyle)
            + focusPoints(user.coreFocus ?? "", partner.partnerCoreFocus)
            + decisionPoints(user.decisionStyle ?? "", partner.partnerDecisionStyle)
            + temperamentPoints(user.socialType ?? "", partner.partnerSocialType)
            + emotionalCorePoints(user.emotionalCore ?? "", partner.partnerEmotionalCore)
    }

    private static func conflictPoints(_ first: String, _ second: String) -> Int {
        switch Set([first, second]) {
            case ["mediator"]: 25
            case ["mediator", "direct"]: 20
            case ["mediator", "avoider"]: 15
            case ["direct"]: 12
            case ["avoider"]: 8
            default: 0
        }
    }

    private static func focusPoints(_ first: String, _ second: String) -> Int {
        switch Set([first, second]) {
            case ["stability"], ["growth"], ["peace"]: 25
            case ["stability", "peace"]: 15
            case ["growth", "peace"]: 10
            default: 5
        }
    }

    private static func decisionPoints(_ first: String, _ second: String) -> Int {
        switch Set([first, second]) {
            case ["planner"]: 20
            case ["spontaneous"]: 15
            case ["planner", "spontaneous"]: 12
            case ["spontaneous", "procrastinator"]: 8
            case ["procrastinator"]: 5
            default: 2
        }
    }

    private static func temperamentPoints(_ first: String, _ second: String) -> Int {
        switch Set([first, second]) {
            case ["ambivert"]: 15
            case ["ambivert", "introvert"], ["ambivert", "extrovert"]: 13
            case ["introvert"], ["extrovert"]: 11
            default: 3
        }
    }

    private static func emotionalCorePoints(_ first: String, _ second: String) -> Int {
        first == second ? 15 : 5
    }
}
