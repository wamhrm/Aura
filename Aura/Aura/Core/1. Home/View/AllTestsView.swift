//
//  TestsView.swift
//  Aura
//
//  Created by ddorsat on 05.05.2026.
//

import SwiftUI

struct AllTestsView: View {
    @ObservedObject var vm: HomeViewModel

    var body: some View {
        ZStack {
            BackgroundView()
            
            if vm.isServerWakingUp {
                ServerWakingUpView(isVisible: vm.isServerWakingUp)
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
                                vm.homeRoutes.append(.testDetails(test))
                            }
                        }
                        
                        ClassicButton(title: vm.isLoading ? "Готовим результат..." : "Проверить себя") {
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
        .animation(.easeInOut(duration: 0.25), value: vm.isServerWakingUp)
        .navigationTitle("Проверить себя")
        .navigationBarTitleDisplayMode(.inline)
        .alert(vm.alertMessage, isPresented: $vm.showAlert) {
            Button("OK", role: .cancel) {}
        }
    }
}

#Preview {
    NavigationStack {
        AllTestsView(vm: HomeViewModel(authService: AuthService(),
                                       contentService: ContentService()))
    }
}
