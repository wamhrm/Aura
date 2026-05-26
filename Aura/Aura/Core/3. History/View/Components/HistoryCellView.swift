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
        HStack(spacing: 15) {
            Text(cell.zodiacSign)
                .font(.title2)
                .padding(10)
                .background(LinearGradient(colors: [.softPurple,
                                                    .idealPartnerType1],
                                           startPoint: .top,
                                           endPoint: .bottom))
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .clipShape(Circle())
                .shadow(radius: 1)

            VStack(alignment: .leading, spacing: 7) {
                Text(titleText)
                    .font(Components.isRegular(.footnote, .callout))
                    .bold()

                Text(cell.archetypeSubtitle)
                    .font(Components.isRegular(.caption, .footnote))
                    .foregroundStyle(.deepGray)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .topTrailing) {
                if cell.kind == .compatibility {
                    Text("\(cell.compatibilityResult?.compatibilityScore ?? 0)%")
                        .font(Components.isRegular(.caption2, .caption))
                        .foregroundStyle(.white)
                        .bold()
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .background(.softPurple.opacity(0.75))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                }
            }
        }
        .padding(.horizontal)
        .frame(height: Components.isRegular(84, 88))
        .frame(maxWidth: .infinity, alignment: .leading)
        .backgroundWithShape(12, .white, true)
    }
}

extension HistoryCellView {
    private var titleText: String {
        switch cell.kind {
            case .personality:
                return cell.archetypeTitle
            case .compatibility:
                return cell.compatibilityResult?.partnerName ?? ""
        }
    }

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
    VStack {
        HistoryCellView(cell: .personalityPlaceholder)
        HistoryCellView(cell: .compatibilityPlaceholder)
    }
    .padding(.horizontal)
}
