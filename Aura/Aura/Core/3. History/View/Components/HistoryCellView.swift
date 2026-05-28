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
            Text(iconHandler)
                .zodiacSingModifier()

            VStack(alignment: .leading, spacing: 7) {
                Text(titleText)
                    .font(Components.displaySize(.callout, .default))
                    .bold()

                Text(cell.archetypeSubtitle)
                    .font(.system(size: Components.displaySize(14, 15)))
                    .foregroundStyle(.deepGray)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .topTrailing) {
                if cell.kind == .compatibility {
                    Text("\(cell.compatibilityResult?.compatibilityScore ?? 0)%")
                        .font(Components.displaySize(.footnote, .system(size: 14)))
                        .foregroundStyle(.white)
                        .bold()
                        .padding(.vertical, 3)
                        .padding(.horizontal, 6)
                        .background(.softPurple.opacity(0.75))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                }
            }
        }
        .padding(.horizontal)
        .frame(height: Components.displaySize(93, 97))
        .frame(maxWidth: .infinity, alignment: .leading)
        .backgroundWithShape(12, .cardBackground, true)
    }
}

extension HistoryCellView {
    private var iconHandler: String {
        switch cell.kind {
            case .personality:
                return cell.zodiacSign
            case .compatibility:
                let sign = cell.compatibilityResult?.partnerZodiacSign ?? ""
                return sign.isEmpty ? "👤" : sign
        }
    }

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
