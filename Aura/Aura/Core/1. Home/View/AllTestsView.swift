//
//  TestsView.swift
//  Aura
//
//  Created by wamhrm on 05.05.2026.
//

import SwiftUI

struct AllTestsView: View {
    @ObservedObject var vm: HomeViewModel

    var body: some View {
        ZStack {
            BackgroundView()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(PersonalityTestTypes.allCases, id: \.self) { test in
                        TestCellView(type: test,
                                     hasChosenTest: vm.isSelected(test)) {
                            vm.toggleTestSelection(test)
                        } onTapHandler: {
                            vm.showTestDetails(test)
                        }
                    }
                    
                    ClassicButton(title: "Проверить себя") {
                        vm.makePersonalityTest()
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Проверить себя")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AllTestsView(vm: HomeViewModel(authService: AuthService.preview,
                                       contentService: ContentService.preview))
    }
}
