//
//  HistoryCellView.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import SwiftUI

struct HistoryCellView: View {
    let cell: HistoryCellModel
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

    var body: some View {
        HStack(spacing: 15) {
            Text(iconHandler)
                .zodiacSingModifier()

            VStack(alignment: .leading, spacing: 7) {
                Text(titleText)
                    .font(Adaptive.size(.callout, .default))
                    .bold()

                Text(cell.archetypeSubtitle)
                    .font(.system(size: Adaptive.size(14, 15)))
                    .foregroundStyle(.deepGray)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .topTrailing) {
                if cell.kind == .compatibility {
                    Text("\(cell.compatibilityResult?.compatibilityScore ?? 0)%")
                        .font(Adaptive.size(.footnote, .system(size: 14)))
                        .foregroundStyle(.white)
                        .bold()
                        .padding(.vertical, 3)
                        .padding(.horizontal, 6)
                        .background(AccentColorOption.color(accentColor).opacity(0.75))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                }
            }
        }
        .padding(.horizontal)
        .frame(height: Adaptive.size(93, 97))
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
            case .personality: cell.archetypeTitle
            case .compatibility: cell.compatibilityResult?.partnerName ?? ""
        }
    }
}

#Preview {
    VStack {
        HistoryCellView(cell: .personalityPlaceholder)
        HistoryCellView(cell: .compatibilityPlaceholder)
    }
    .padding(.horizontal)
}
