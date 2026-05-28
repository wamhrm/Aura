//
//  TestsView.swift
//  Aura
//
//  Created by ddorsat on 05.05.2026.
//

import SwiftUI

struct AllTestsView: View {
    @ObservedObject var vm: HomeViewModel
    private let onTapHandler: (PersonalityTestTypes) -> Void

    init(vm: HomeViewModel, onTapHandler: @escaping (PersonalityTestTypes) -> Void) {
        self.vm = vm
        self.onTapHandler = onTapHandler
    }

    var body: some View {
        ZStack {
            Components.backgroundColor()
            
            if vm.isServerWakingUp {
                Components.serverWakingUpView(vm.isServerWakingUp)
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
                    .disabled(vm.isLoading)
                    .padding(.horizontal)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle("Проверить себя")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.25), value: vm.isServerWakingUp)
    }
}

#Preview {
    NavigationStack {
        AllTestsView(vm: HomeViewModel(authService: AuthService(),
                                       contentService: ContentService())) { _ in
            
        }
    }
}
