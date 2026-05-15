//
//  TestsView.swift
//  Aura
//
//  Created by ddorsat on 05.05.2026.
//

import SwiftUI

struct AllTestsView: View {
    @ObservedObject var vm: HomeViewModel
    let onTapHandler: (TestTypes) -> Void
    
    var body: some View {
        ZStack {
            Components.backgroundColor()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(TestTypes.allCases, id: \.self) { test in
                        TestCellView(type: test,
                                     hasChosenTest: Binding(
                                        get: { vm.selectedTests.contains(test) },
                                        set: { _ in })) {
                            vm.toggleTestSelection(test)
                        } onTapHandler: {
                            onTapHandler(test)
                        }
                    }
                    
                    Components.classicButton("Проверить себя") {
                        vm.generatePersonality()
                    }
                    .disabled(vm.isLoading)
                    .padding(.top, 10)

                    if vm.isLoading {
                        ProgressView("Готовим результат")
                            .frame(maxWidth: .infinity)
                    }
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
        AllTestsView(vm: HomeViewModel(authService: AuthService(), personalityService: PersonalityService())) { _ in
            
        }
    }
}
