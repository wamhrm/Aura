//
//  HomeView.swift
//  Aura
//
//  Created by wamhrm on 31.03.2026.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var vm: HomeViewModel
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

    let compatibilityButton: () -> Void
    let aiConsentButton: () -> Void

    var body: some View {
        NavigationStack(path: $vm.homeRoutes) {
            ZStack {
                BackgroundView()

                if vm.isLoadingScreen {
                    ProgressView()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack(spacing: 15) {
                                LogoImage(size: 32)

                                Text(vm.greetingText)
                                    .font(Adaptive.size(.callout, .default))
                                    .fontWeight(.semibold)
                                    .fontDesign(.monospaced)

                                Spacer()
                            }

                            VStack(alignment: .leading, spacing: 15) {
                                Text("ИНСАЙТ ДНЯ")
                                    .font(Adaptive.size(.callout, .default))
                                    .fontWeight(.heavy)

                                if vm.allowsAIAnalysis {
                                    Text(vm.dailyInsightHandler)
                                        .font(.system(size: Adaptive.size(14, 15))).italic()
                                        .fontWeight(.medium)
                                } else {
                                    AIConsentLock(title: "Разрешите анализ с помощью AI, чтобы получать инсайт дня",
                                                  onAllow: aiConsentButton)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .foregroundStyle(.white)
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AccentColorOption.color(accentColor).opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            if let horoscope = vm.horoscope {
                                VStack(alignment: .leading, spacing: 10) {
                                    headerText("Гороскоп на неделю", "Читать") {
                                        vm.showHoroscopeDetails()
                                    }

                                    HoroscopeCellView(horoscope: horoscope) {
                                        vm.showHoroscopeDetails()
                                    }
                                }
                                .padding(.top, 15)
                            }

                            Button {
                                compatibilityButton()
                            } label: {
                                HStack {
                                    Text("Проверить совместимость")
                                        .font(Adaptive.size(.system(size: 18), .title3))
                                        .bold()
                                        .foregroundStyle(.white)
                                    
                                    Spacer()

                                    sparkImageWithBackground(Adaptive.size(.medium, .large), .white)
                                }
                                .padding(.horizontal, 7)
                                .padding(18)
                                .frame(maxWidth: .infinity)
                                .background(LinearGradient(colors: [.purple, .blue],
                                                           startPoint: .leading,
                                                           endPoint: .trailing))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                headerText("Проверьте себя", "Все тесты") {
                                    vm.showAllTests()
                                }
                                .disabled(!vm.allowsAIAnalysis)

                                ForEach(PersonalityTestTypes.allCases[0...2], id: \.self) { test in
                                    TestCellView(type: test,
                                                 hasChosenTest: vm.isSelected(test)) {
                                                        vm.toggleTestSelection(test)
                                                    } onTapHandler: {
                                                        vm.showTestDetails(test)
                                                    }
                                }
                                .disabled(!vm.allowsAIAnalysis)

                                ClassicButton(title: vm.testButtonTitle) {
                                    vm.makePersonalityTest()
                                }
                                .disabled(vm.isLoading || !vm.allowsAIAnalysis)
                                .padding(.top, 10)
                            }
                            .blur(radius: !vm.allowsAIAnalysis ? 5 : 0)
                            .padding(.top, 15)
                            .overlay {
                                if !vm.allowsAIAnalysis {
                                    AIConsentLock(title: "Разрешите анализ с помощью AI для прохождения тестов",
                                                  onAllow: aiConsentButton)
                                }
                            }
                        }
                        .disabled(vm.isLoading)
                        .padding(.horizontal)
                    }
                    .bottomAreaPadding(50)
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("Главная")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: HomeRoutes.self) { destination in
                destinationView(destination)
            }
            .alert(vm.alertMessage, isPresented: $vm.showAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }
}

extension HomeView {
    private func headerText(_ title: String,
                            _ buttonTitle: String,
                            _ onTapHandler: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .fontWeight(.semibold)
                .padding(.leading, 4)

            Spacer()

            Button {
                onTapHandler()
            } label: {
                Text(buttonTitle)
                    .foregroundStyle(AccentColorOption.color(accentColor))
                    .fontWeight(.medium)
            }
        }
        .font(Adaptive.size(.system(size: 15), .default))
    }

    @ViewBuilder
    private func destinationView(_ route: HomeRoutes) -> some View {
        switch route {
            case .horoscopeDetails:
                if let horoscope = vm.horoscope {
                    HoroscopeDetailsView(horoscope: horoscope)
                }
            case .allTests:
                AllTestsView(vm: vm)
            case .testDetails(let test):
                TestDetailsView(type: test, isSelected: vm.isSelected(test)) {
                    vm.toggleTestSelection(test)
                }
            case .testResults:
                if let result = vm.personalityResult {
                    PersonalityResultView(result: result)
                }
        }
    }

    private func sparkImageWithBackground(_ size: Image.Scale, _ color: Color) -> some View {
        Image(systemName: "sparkles")
            .imageScale(size)
            .foregroundStyle(color)
            .padding(8)
            .background(Color.fieldBackground.opacity(0.15))
            .clipShape(Circle())
    }
}

#Preview {
    HomeView(vm: HomeViewModel(authService: AuthService(),
                               contentService: ContentService())) {

    } aiConsentButton: {

    }
}
