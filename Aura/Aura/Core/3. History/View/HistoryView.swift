//
//  HistoryView.swift
//  Aura
//
//  Created by ddorsat on 04.05.2026.
//

import SwiftUI

struct HistoryView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Components.backgroundColor()

                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        SelectionButtons<HistoryFilterTypes> { filter in

                        }

                        ForEach(0..<7) { _ in
                            HistoryCellView()
                        }
                    }
                    .padding(.horizontal)
                }
                .navigationTitle("История совместимостей")
                .navigationBarTitleDisplayMode(.inline)
                .bottomAreaPadding()
            }
        }
    }
}

enum HistoryFilterTypes: String, CaseIterable {
    case latest = "Последние"
    case highest = "Высокие"
    case lowest = "Низкие"
}

#Preview {
    NavigationStack {
        HistoryView()
    }
}
