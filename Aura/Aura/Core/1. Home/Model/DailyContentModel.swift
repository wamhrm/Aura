//
//  DailyContentModel.swift
//  Aura
//
//  Created by wamhrm on 26.05.2026.
//

import Foundation

struct DailyContentModel: Identifiable, Hashable, Codable {
    let id: UUID
    let text: String
    let dateCreated: String

    // The server dates the content by the time zone the app sends
    var isFromToday: Bool {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return dateCreated == formatter.string(from: Date())
    }
}
