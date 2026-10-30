//
//  ResultSectionView.swift
//  Aura
//
//  Created by wamhrm on 31.10.2026.
//

import SwiftUI

struct ResultSectionView<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(Adaptive.size(.system(size: 15), .default))
                .bold()

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .backgroundWithShape(12, .cardBackground, true)
    }
}

#Preview {
    ResultSectionView(title: "Общее") {
        Text("Описание результата теста")
            .foregroundStyle(.deepGray)
    }
    .padding(.horizontal)
}
