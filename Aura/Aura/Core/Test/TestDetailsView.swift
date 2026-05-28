//
//  TestDetailsView.swift
//  Aura
//
//  Created by ddorsat on 05.05.2026.
//

import SwiftUI

struct TestDetailsView<Test: TestCellDisplayable>: View {
    let type: Test
    let isSelected: Bool
    let onTapHandler: () -> Void

    var body: some View {
        ZStack {
            Components.backgroundColor()
            
            VStack(alignment: .leading, spacing: 20) {
                Components.testCellImage(type.icon, type.color, .title, Components.displaySize(55, 58), false)
                
                Text(type.deepDescription)
                    .font(Components.displaySize(.system(size: 15), .callout))
                    .foregroundStyle(.deepGray)
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Что включено")
                        .font(Components.displaySize(.system(size: 15), .default))
                        .bold()
                        .padding(.bottom, 5)
                    
                    ForEach(type.includedItems, id: \.self) { item in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.deepGray)
                                .font(Components.displaySize(.footnote, .system(size: 14)))
                                .bold()
                                .padding(7)
                                .background(.blue.opacity(0.1))
                                .clipShape(Circle())
                            
                            Text(item)
                                .font(Components.displaySize(.footnote, .system(size: 14)))
                                .foregroundStyle(.deepGray)
                                .fontWeight(.medium)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .backgroundWithShape(12, .cardBackground, true)
                
                Components.classicButton(isSelected ? "Убрать" : "Выбрать") {
                    onTapHandler()
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .navigationTitle(type.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TestDetailsView(type: PersonalityTestTypes.astrology, isSelected: false) {

        }
    }
}
