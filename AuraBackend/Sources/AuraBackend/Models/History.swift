//
//  History.swift
//  AuraBackend
//
//  Created by wamhrm on 13.05.2026.
//

import Fluent
import Foundation

final class History: Model, @unchecked Sendable {
    static let schema = "history"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Field(key: "request_id")
    var requestID: UUID

    @Field(key: "kind")
    var kind: TestKind

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Field(key: "selected_tests")
    var selectedTests: [String]

    @Field(key: "title")
    var title: String

    @Field(key: "subtitle")
    var subtitle: String

    @Field(key: "zodiac_sign")
    var zodiacSign: String

    @OptionalField(key: "compatibility_score")
    var compatibilityScore: Int?

    @OptionalField(key: "partner_name")
    var partnerName: String?

    @OptionalField(key: "partner_zodiac_sign")
    var partnerZodiacSign: String?

    @Field(key: "result")
    var result: String

    init() {}

    init(userID: User.IDValue,
         requestID: UUID,
         kind: TestKind,
         selectedTests: [String],
         title: String,
         subtitle: String,
         zodiacSign: String,
         compatibilityScore: Int? = nil,
         partnerName: String? = nil,
         partnerZodiacSign: String? = nil,
         result: String) {
        self.$user.id = userID
        self.requestID = requestID
        self.kind = kind
        self.selectedTests = selectedTests
        self.title = title
        self.subtitle = subtitle
        self.zodiacSign = zodiacSign
        self.compatibilityScore = compatibilityScore
        self.partnerName = partnerName
        self.partnerZodiacSign = partnerZodiacSign
        self.result = result
    }
}

enum TestKind: String, Codable, Sendable {
    case personality, compatibility
}
