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
                Components.testCellImage(type.icon, type.color, .title, 60, false)
                
                Text(type.deepDescription)
                    .font(.callout)
                    .foregroundStyle(.deepGray)
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Что включено")
                        .bold()
                        .padding(.bottom, 5)
                    
                    ForEach(type.includedItems, id: \.self) { item in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.deepGray)
                                .imageScale(.small)
                                .fontWeight(.medium)
                                .padding(8)
                                .background(.blue.opacity(0.1))
                                .clipShape(Circle())
                            
                            Text(item)
                                .foregroundStyle(.deepGray)
                                .fontWeight(.medium)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .backgroundWithShape(15, true)
                
                Components.classicButton(isSelected ? "Убрать" : "Выбрать") {
                    onTapHandler()
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .navigationTitle(type.title)
        .navigationBarTitleDisplayMode(.inline)
        .scrollIndicators(.hidden)
    }
}

#Preview {
    NavigationStack {
        TestDetailsView(type: TestTypes.astrology, isSelected: false) {

        }
    }
}
