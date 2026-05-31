//
//  PartnerInfoModelz.swift
//  Aura
//
//  Created by ddorsat on 18.05.2026.
//

import Foundation

struct PartnerInfoModel {
    var name = ""
    var gender = "Мужской"
    var exactDateOfBirth = true
    var dateOfBirth = ""
    var birthTime = ""
    var age = ""

    func compatibilityTestRequest(selectedTests: [CompatibilityTestTypes]) -> CompatibilityTestRequest {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let gender = gender.trimmingCharacters(in: .whitespacesAndNewlines)
        let date = dateOfBirth.trimmingCharacters(in: .whitespacesAndNewlines)
        let time = birthTime.trimmingCharacters(in: .whitespacesAndNewlines)
        let age = age.trimmingCharacters(in: .whitespacesAndNewlines)

        return CompatibilityTestRequest(
            partnerName: name,
            partnerDateOfBirth: exactDateOfBirth && !date.isEmpty ? date : nil,
            partnerBirthTime: exactDateOfBirth && !time.isEmpty ? time : nil,
            partnerAge: exactDateOfBirth ? nil : (age.isEmpty ? nil : age),
            partnerGender: gender,
            exactDateOfBirth: exactDateOfBirth,
            selectedTests: selectedTests.map(\.rawValue))
    }
}
