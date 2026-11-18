//
//  CompatibilityView.swift
//  Aura
//
//  Created by wamhrm on 18.05.2026.
//

import SwiftUI

struct CompatibilityView: View {
    @ObservedObject var vm: CompatibilityViewModel
    let aiConsentButton: () -> Void

    var body: some View {
        ZStack {
            NavigationStack(path: $vm.compatibilityRoutes) {
                ZStack {
                    BackgroundView()

                    ScrollView {
                        VStack(spacing: 25) {
                            headerView()

                            VStack(alignment: .leading, spacing: 25) {
                                HStack(spacing: 10) {
                                    Image(systemName: "heart")
                                        .font(Adaptive.size(.callout, .default, .default))
                                        .foregroundStyle(.tint)
                                        .fontWeight(.semibold)
                                        .padding(Adaptive.size(7, 7, 9))
                                        .background(.capsuleBackground)
                                        .clipShape(.circle)

                                    Text(AppLanguage.text("Детали партнера"))
                                        .font(Adaptive.size(.system(size: 15), .callout, .default))
                                        .bold()

                                    Spacer()
                                }

                                VStack(alignment: .leading) {
                                    headerText(AppLanguage.text("Имя *"))

                                    CompatibilityTextFieldView(title: AppLanguage.text("Введите имя"),
                                                               text: $vm.partnerInfo.name)
                                }

                                BirthDateFieldsView(birthDate: $vm.partnerInfo.birthDate,
                                                    knowsBirthTime: $vm.partnerInfo.knowsBirthTime,
                                                    birthTime: $vm.partnerInfo.birthTime,
                                                    dateRange: BirthDateFormatter.dateRange)
                            }
                            .padding(20)
                            .backgroundWithShape(12, .cardBackground, showsStroke: true)

                            VStack(alignment: .leading, spacing: Adaptive.size(10, 10, 12)) {
                                HStack {
                                    Text(AppLanguage.text("Выберите тесты"))
                                        .fontWeight(.semibold)
                                        .padding(.leading, 4)

                                    Spacer()

                                    Button {
                                        vm.selectAllTests()
                                    } label: {
                                        Text(AppLanguage.text("Выбрать все"))
                                            .foregroundStyle(.tint)
                                            .fontWeight(.medium)
                                    }
                                }
                                .font(Adaptive.size(.system(size: 15), .callout, .default))

                                ForEach(vm.availableTests, id: \.self) { test in
                                    TestCellView(type: test,
                                                 hasChosenTest: vm.isSelected(test)) {
                                        vm.toggleTestSelection(test)
                                    } onTapHandler: {
                                        vm.showTestDetails(test)
                                    }
                                }

                                ClassicButton(title: AppLanguage.text("Узнать совместимость")) {
                                    vm.makeCompatibilityTest()
                                }
                                .padding(.top, 10)
                            }
                            .blur(radius: vm.needsAIConsent ? 5 : 0)
                            .disabled(vm.needsAIConsent)
                            .overlay {
                                if vm.needsAIConsent {
                                    AIConsentLock(title: AppLanguage.text("Разрешите анализ с помощью AI для теста совместимости"),
                                                  onAllow: aiConsentButton)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .bottomAreaPadding(50)
                    }
                    .scrollIndicators(.hidden)
                    .dismissKeyboardOnTap()
                    .scrollDismissesKeyboard(.interactively)
                }
                .navigationTitle(AppLanguage.text("Узнать совместимость"))
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: CompatibilityRoutes.self) { destination in
                    destinationView(destination)
                }
            }
            .opacity(vm.isLoading ? 0 : 1)

            ZStack {
                BackgroundView()
                LoadingView(title: AppLanguage.text("Готовим результат..."), isPresented: vm.isLoading)
            }
            .opacity(vm.isLoading ? 1 : 0)
        }
        .animation(.easeInOut(duration: 0.35), value: vm.isLoading)
        .alert(vm.alertMessage, isPresented: vm.alertBinding) {
            Button("OK", role: .cancel) {}
        }
        .sheet(item: $vm.emailConfirmation) { confirmation in
            EmailConfirmationSheetView(vm: confirmation)
        }
    }
}

extension CompatibilityView {
    private func headerText(_ title: String) -> some View {
        Text(title)
            .font(Adaptive.size(.footnote, .system(size: 14), .system(size: 14)))
            .foregroundStyle(.deepGray)
            .fontWeight(.medium)
    }

    private func headerView() -> some View {
        VStack(alignment: .center, spacing: 7) {
            Image(systemName: "heart")
                .font(Adaptive.size(.title2, .system(size: 24), .title))
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(15)
                .background(LinearGradient(colors: [.purple, .softPurple],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing))
                .clipShape(.circle)
                .padding(.vertical, 12)

            Text(AppLanguage.text("Анализ партнера"))
                .font(Adaptive.size(.default, .system(size: 18), .title3))
                .bold()

            Text(AppLanguage.text("Введите информацию о партнере"))
                .font(Adaptive.size(.system(size: 14), .system(size: 15), .callout))
                .foregroundStyle(.deepGray)
                .fontWeight(.medium)
        }
    }

    @ViewBuilder
    private func destinationView(_ route: CompatibilityRoutes) -> some View {
        switch route {
            case .testDetails(let test):
                TestDetailsView(type: test,
                                isSelected: vm.isSelected(test)) {
                    vm.toggleTestSelection(test)
                }
            case .compatibilityResults:
                if let result = vm.compatibilityResult {
                    CompatibilityResultView(result: result)
                }
        }
    }
}

#Preview {
    let services = PreviewServices()
    NavigationStack {
        CompatibilityView(vm: CompatibilityViewModel(authService: services.authService,
                                                     contentService: services.contentService)) {

        }
    }
}
