//
//  PartnerInfoModelz.swift
//  Aura
//
//  Created by wamhrm on 18.05.2026.
//

import Foundation

struct PartnerInfoModel {
    var name = ""
    var gender = ProfileInfoOption.man.rawValue
    var birthDate = BirthDateFormatter.defaultDate
    var knowsBirthTime = false
    var birthTime = BirthDateFormatter.defaultTime
    var answers = ProfileInfoModel()

    var hasAllAnswers: Bool {
        answers.socialType != nil &&
        answers.conflictStyle != nil &&
        answers.emotionalCore != nil &&
        answers.decisionStyle != nil &&
        answers.coreFocus != nil
    }

    func compatibilityTestRequest(selectedTests: [CompatibilityTestTypes]) -> CompatibilityTestRequest {
        CompatibilityTestRequest(
            partnerName: name.trimmingCharacters(in: .whitespacesAndNewlines),
            partnerDateOfBirth: BirthDateFormatter.dateString(from: birthDate),
            partnerBirthTime: knowsBirthTime ? BirthDateFormatter.timeString(from: birthTime) : nil,
            partnerGender: gender,
            partnerSocialType: answers.socialType ?? "",
            partnerConflictStyle: answers.conflictStyle ?? "",
            partnerEmotionalCore: answers.emotionalCore ?? "",
            partnerDecisionStyle: answers.decisionStyle ?? "",
            partnerCoreFocus: answers.coreFocus ?? "",
            selectedTests: selectedTests.map(\.rawValue))
    }
}
