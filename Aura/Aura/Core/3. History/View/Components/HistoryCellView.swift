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
                    if cell.kind == .personality {
                        HStack {
                            Text(cell.archetypeTitle)
                                .font(.callout)
                                .bold()

                            Spacer()

                            Text(formattedDate)
                                .font(.footnote)
                                .foregroundStyle(.deepGray)
                                .fontWeight(.medium)
                        }
                        .lineLimit(2)

                        Text(cell.archetypeSubtitle)
                            .font(.footnote)
                            .foregroundStyle(.deepGray)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                    } else {
                        HStack {
                            Text(cell.compatibilityResult?.partnerName ?? "")
                                .font(.callout)
                                .bold()
                            
                            Spacer()
                            
                            Text("\(cell.compatibilityResult?.compatibilityScore ?? 0)%")
                                .font(.footnote)
                                .foregroundStyle(.white)
                                .bold()
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(.softPurple.opacity(0.75))
                                .clipShape(RoundedRectangle(cornerRadius: 11))
                        }
                        .lineLimit(2)

                        Text(cell.compatibilityResult?.subtitle ?? "")
                            .font(.footnote)
                            .foregroundStyle(.deepGray)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                    }
                }
                .multilineTextAlignment(.leading)
            }
        }
        .padding()
        .backgroundWithShape(15, true)
    }
}

extension HistoryCellView {
    private var formattedDate: String {
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime]
        guard let date = parser.date(from: cell.createdAt) else { return cell.createdAt }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    HistoryCellView(cell: HistoryCellModel(id: UUID(),
                                           kind: .personality,
                                           createdAt: "2026-05-19T12:00:00Z",
                                           selectedTests: ["Астрология"],
                                           archetypeTitle: "Интуитивный креатор",
                                           archetypeSubtitle: "Вы стремитесь к глубине",
                                           zodiacSign: "♒",
                                           personalityResult: nil,
                                           compatibilityResult: nil))
}
