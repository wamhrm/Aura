//
//  HistoryCellView.swift
//  Aura
//
//  Created by wamhrm on 31.03.2026.
//

import SwiftUI

struct HistoryCellView: View {
    let cell: HistoryCellModel

    var body: some View {
        HStack(spacing: 15) {
            Text(cell.displayIcon)
                .zodiacSignModifier()

            VStack(alignment: .leading, spacing: 7) {
                Text(cell.titleText)
                    .font(Adaptive.size(.callout, .default, .default))
                    .bold()
                    .lineLimit(1)
                    .padding(.trailing, cell.kind == .compatibility ? 64 : 0)

                Text(cell.archetypeSubtitle)
                    .font(.system(size: Adaptive.size(14, 15, 15)))
                    .foregroundStyle(.deepGray)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .padding(.trailing, cell.kind == .compatibility ? 64 : 0)

                Text(cell.dateText)
                    .font(Adaptive.size(.caption, .footnote, .footnote))
                    .foregroundStyle(.deepGray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .topTrailing) {
                if cell.kind == .compatibility {
                    Text(cell.compatibilityScoreText)
                        .font(Adaptive.size(.footnote, .system(size: 14), .system(size: 14)))
                        .foregroundStyle(.white)
                        .bold()
                        .padding(.vertical, 3)
                        .padding(.horizontal, 6)
                        .background(.accentBlue)
                        .clipShape(.rect(cornerRadius: 8))
                }
            }
        }
        .padding(.horizontal)
        .frame(height: Adaptive.size(112, 118, 118))
        .frame(maxWidth: .infinity, alignment: .leading)
        .backgroundWithShape(12, .cardBackground, showsStroke: true)
    }
}

#Preview {
    VStack {
        HistoryCellView(cell: .personalityPlaceholder)
        HistoryCellView(cell: .compatibilityPlaceholder)
    }
    .padding(.horizontal)
}
