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
                Components.testCellImage(type.icon, type.color, .title, Components.isRegular(55, 57), false)
                
                Text(type.deepDescription)
                    .font(Components.isRegular(.system(size: 15), .system(size: 17)))
                    .foregroundStyle(.deepGray)
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Что включено")
                        .font(Components.isRegular(.callout, .default))
                        .bold()
                        .padding(.bottom, 5)
                    
                    ForEach(type.includedItems, id: \.self) { item in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.deepGray)
                                .font(Components.isRegular(.footnote, .callout))
                                .bold()
                                .padding(7)
                                .background(.blue.opacity(0.1))
                                .clipShape(Circle())
                            
                            Text(item)
                                .font(Components.isRegular(.footnote, .callout))
                                .foregroundStyle(.deepGray)
                                .fontWeight(.medium)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .backgroundWithShape(12, .white, true)
                
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
