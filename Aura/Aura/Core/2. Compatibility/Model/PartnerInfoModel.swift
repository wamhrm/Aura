//
//  PartnerInfoModelz.swift
//  Aura
//
//  Created by wamhrm on 18.05.2026.
//

import Foundation

struct PartnerInfoModel {
    var name = ""
    var birthDate = BirthDateFormatter.defaultDate
    var knowsBirthTime = false
    var birthTime = BirthDateFormatter.defaultTime

    func compatibilityTestRequest(selectedTests: [CompatibilityTestTypes]) -> CompatibilityTestRequest {
        CompatibilityTestRequest(
            partnerName: name.trimmingCharacters(in: .whitespacesAndNewlines),
            partnerDateOfBirth: BirthDateFormatter.dateString(date: birthDate),
            partnerBirthTime: knowsBirthTime ? BirthDateFormatter.timeString(date: birthTime) : nil,
            selectedTests: selectedTests.map(\.rawValue))
    }
}
