//
//  HoroscopeModel.swift
//  Aura
//
//  Created by ddorsat on 21.05.2026.
//

import Foundation

struct HoroscopeModel: Identifiable, Hashable, Decodable {
    let id: UUID
    let type: HoroscopeType
    let dateStart: String
    let dateEnd: String
    let description: String
    let items: [HoroscopeSphereItem]
}

struct HoroscopeSphereItem: Hashable, Decodable {
    let title: HoroscopeDetailsCellType
    let description: String
}

extension HoroscopeModel {
    static let mock = HoroscopeModel(id: UUID(),
                                     type: .aquarius,
                                     dateStart: "21 мар",
                                     dateEnd: "5 мая",
                                     description: "Фортуна благоволит смелым на этой неделе. Сделайте тот шаг, о котором долго думали. Жизнь не стоит на месте, двигайтесь, гуляйте, проводите время с друзьями.",
                                     items: [HoroscopeSphereItem(title: .love,
                                                                 description: "Эта неделя может стать особенно тяжелой для вашего сердца. Откровенный разговор с близким человеком укрепит ваши отношения."),
                                             HoroscopeSphereItem(title: .health,
                                                                 description: "Уделите внимание режиму сна и отдыху — организм попросит паузу."),
                                             HoroscopeSphereItem(title: .work,
                                                                 description: "На работе лучше двигаться размеренно и не брать лишних обязательств.")])
}
