//
//  TestsView.swift
//  Aura
//
//  Created by ddorsat on 05.05.2026.
//

import SwiftUI

struct AllTestsView: View {
    @ObservedObject var vm: HomeViewModel
    let onTapHandler: (TestType) -> Void
    
    var body: some View {
        ZStack {
            Components.backgroundColor()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(TestType.allCases, id: \.self) { test in
                        TestCellView(type: test,
                                     showSelection: true,
                                     hasChosenTest: Binding(
                                        get: { vm.selectedTests.contains(test) },
                                        set: { _ in })) {
                            vm.toggleTestSelection(test)
                        } onTapHandler: {
                            onTapHandler(test)
                        }
                    }
                    
                    Components.classicButton("Проверить себя") {
                        vm.homeRoutes.append(.testResults)
                    }
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Проверить себя")
            .navigationBarTitleDisplayMode(.inline)
            .scrollIndicators(.hidden)
            .padding(.horizontal)
        }
    }
}

#Preview {
    NavigationStack {
        AllTestsView(vm: HomeViewModel()) { _ in
            
        }
    }
}
