//
//  HistoryCellView.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import SwiftUI

struct HistoryCellView: View {
    let cell: HistoryCellModel

    var body: some View {
        VStack {
            HStack(alignment: .top, spacing: 15) {
                Text(cell.zodiacSign)
                    .font(.title2)
                    .padding(10)
                    .background(LinearGradient(colors: [.softPurple, .idealPartnerType1], startPoint: .top, endPoint: .bottom))
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .clipShape(Circle())
                    .shadow(radius: 1)
                    .padding(.top, 5)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(cell.archetypeTitle)
                            .bold()

                        Spacer()

                        Text(cell.formattedCreatedAt)
                            .font(.footnote)
                            .foregroundStyle(.deepGray)
                            .fontWeight(.medium)
                    }

                    Text(cell.archetypeSubtitle)
                        .font(.callout)
                        .foregroundStyle(.deepGray)
                }
            }
        }
        .padding()
        .backgroundWithShape(15, true)
    }
}

extension HistoryCellModel {
    var formattedCreatedAt: String {
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime]
        guard let date = parser.date(from: createdAt) else { return createdAt }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    HistoryCellView(cell: HistoryCellModel(id: UUID(),
                                                      createdAt: "2026-05-19T12:00:00Z",
                                                      selectedTests: ["Астрология"],
                                                      archetypeTitle: "Интуитивный креатор",
                                                      archetypeSubtitle: "Вы стремитесь к глубине",
                                                      zodiacSign: "♒"))
}
