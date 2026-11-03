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
    var exactDateOfBirth = true
    var birthDate = BirthDateFormatter.defaultDate
    var knowsBirthTime = false
    var birthTime = BirthDateFormatter.defaultTime
    var age = ""

    func compatibilityTestRequest(selectedTests: [CompatibilityTestTypes]) -> CompatibilityTestRequest {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let gender = gender.trimmingCharacters(in: .whitespacesAndNewlines)
        let age = age.trimmingCharacters(in: .whitespacesAndNewlines)

        return CompatibilityTestRequest(
            partnerName: name,
            partnerDateOfBirth: exactDateOfBirth ? BirthDateFormatter.dateString(from: birthDate) : nil,
            partnerBirthTime: exactDateOfBirth && knowsBirthTime ? BirthDateFormatter.timeString(from: birthTime) : nil,
            partnerAge: !exactDateOfBirth && !age.isEmpty ? age : nil,
            partnerGender: gender,
            exactDateOfBirth: exactDateOfBirth,
            selectedTests: selectedTests.map(\.rawValue))
    }
}
