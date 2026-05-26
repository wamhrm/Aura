//
//  TestsView.swift
//  Aura
//
//  Created by ddorsat on 05.05.2026.
//

import SwiftUI

struct AllTestsView: View {
    @ObservedObject var vm: HomeViewModel
    let onTapHandler: (PersonalityTestTypes) -> Void
    
    var body: some View {
        ZStack {
            Components.backgroundColor()
            
            if vm.isServerWakingUp {
                Components.isServerWakingUpView(vm.isServerWakingUp)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(PersonalityTestTypes.allCases, id: \.self) { test in
                            TestCellView(type: test,
                                         hasChosenTest: Binding(
                                            get: { vm.selectedTests.contains(test) },
                                            set: { _ in })) {
                                vm.toggleTestSelection(test)
                            } onTapHandler: {
                                onTapHandler(test)
                            }
                        }
                        
                        Components.classicButton(vm.isLoading ? "Готовим результат..." : "Проверить себя") {
                            vm.makePersonalityTest()
                        }
                        .disabled(vm.isLoading)
                        .padding(.top, 10)
                    }
                    .padding(.horizontal)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle("Проверить себя")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AllTestsView(vm: HomeViewModel(authService: AuthService(),
                                       contentService: ContentService())) { _ in
            
        }
    }
}
