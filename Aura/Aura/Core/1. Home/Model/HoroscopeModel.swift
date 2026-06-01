//
//  HoroscopeModel.swift
//  Aura
//
//  Created by ddorsat on 21.05.2026.
//

import Foundation

struct HoroscopeModel: Identifiable, Hashable, Codable {
    let id: UUID
    let type: HoroscopeTypes
    let dateStart: String
    let dateEnd: String
    let description: String
    let items: [HoroscopeItems]
}

struct HoroscopeItems: Hashable, Codable {
    let title: HoroscopeDetailsCellTypes
    let description: String
}

extension HoroscopeModel {
    static let mock = HoroscopeModel(id: UUID(),
                                     type: .aquarius,
                                     dateStart: "21 мар",
                                     dateEnd: "5 мая",
                                     description: "Фортуна благоволит смелым на этой неделе. Сделайте тот шаг, о котором долго думали. Жизнь не стоит на месте, двигайтесь, гуляйте, проводите время с друзьями.",
                                     items: [HoroscopeItems(
                                        title: .love,
                                        description: "Эта неделя может стать особенно тяжелой для вашего сердца. Откровенный разговор с близким человеком укрепит ваши отношения."),
                                             HoroscopeItems(
                                        title: .health,
                                        description: "Уделите внимание режиму сна и отдыху — организм попросит паузу."),
                                             HoroscopeItems(
                                        title: .work,
                                        description: "На работе лучше двигаться размеренно и не брать лишних обязательств.")])
}
