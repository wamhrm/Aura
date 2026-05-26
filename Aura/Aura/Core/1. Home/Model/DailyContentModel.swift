//
//  DailyContentModel.swift
//  Aura
//
//  Created by ddorsat on 26.05.2026.
//

import Foundation

struct DailyContentModel: Identifiable, Hashable, Codable {
    let id: UUID
    let text: String
    let dateCreated: String
}
