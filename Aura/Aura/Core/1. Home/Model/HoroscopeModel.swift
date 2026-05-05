//
//  HoroscopeModel.swift
//  Aura
//
//  Created by ddorsat on 05.05.2026.
//

import Foundation

struct HoroscopeModel: Identifiable, Hashable {
    let id: UUID
    let type: HoroscopeType
    let dateStart: String
    let dateEnd: String
    let description: String
}

extension HoroscopeModel {
    static let mock = HoroscopeModel(id: UUID(), type: .aquarius, dateStart: "21 мар", dateEnd: "5 мая", description: "Фортуна благоволит смелым на этой неделе. Сделайте тот шаг, о котором долго думали. Жизнь не стоит на месте, двигайтесь, гуляйте, проводите время с друзьями.")
}
