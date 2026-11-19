//
//  HomeView.swift
//  Aura
//
//  Created by wamhrm on 31.03.2026.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var vm: HomeViewModel
    @Environment(\.scenePhase) private var scenePhase

    let compatibilityButton: () -> Void
    let aiConsentButton: () -> Void

    var body: some View {
        ZStack {
            NavigationStack(path: $vm.homeRoutes) {
                ZStack {
                    BackgroundView()

                    ScrollView {
                        VStack(alignment: .leading, spacing: Adaptive.size(15, 15, 17)) {
                            HStack(spacing: 15) {
                                LogoImage(size: 32)

                                Text(vm.greetingText)
                                    .font(Adaptive.size(.callout, .default, .default))
                                    .fontWeight(.semibold)
                                    .fontDesign(.monospaced)

                                Spacer()
                            }

                            VStack(alignment: .leading, spacing: 15) {
                                Text("ИНСАЙТ ДНЯ")
                                    .font(Adaptive.size(.callout, .default, .default))
                                    .fontWeight(.heavy)

                                if !vm.allowsAIAnalysis {
                                    AIConsentLock(title: "Разрешите анализ с помощью AI, чтобы получать инсайт дня",
                                                  onAllow: aiConsentButton)
                                    .frame(maxWidth: .infinity)
                                } else if let insight = vm.dailyInsight {
                                    Text(insight.text)
                                        .font(.system(size: Adaptive.size(14, 15, 15))).italic()
                                        .fontWeight(.medium)
                                        .transition(.opacity)
                                } else if case .failed(let message) = vm.insightState {
                                    LoadFailedView(message: message) {
                                        vm.retryDailyInsight()
                                    }
                                    .tint(.white)
                                } else {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .foregroundStyle(.white)
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.tint.opacity(0.85))
                            .clipShape(.rect(cornerRadius: 12))
                            .animation(.easeInOut(duration: 0.35), value: vm.dailyInsight?.id)

                            if let horoscope = vm.horoscope {
                                VStack(alignment: .leading, spacing: Adaptive.size(10, 10, 12)) {
                                    headerText(title: "Гороскоп на неделю", buttonTitle: "Читать") {
                                        vm.showHoroscopeDetails()
                                    }

                                    HoroscopeCellView(horoscope: horoscope) {
                                        vm.showHoroscopeDetails()
                                    }
                                }
                                .padding(.top, 15)
                            } else if case .failed(let message) = vm.horoscopeState {
                                VStack(alignment: .leading, spacing: Adaptive.size(10, 10, 12)) {
                                    Text("Гороскоп на неделю")
                                        .font(Adaptive.size(.system(size: 15), .callout, .default))
                                        .fontWeight(.semibold)
                                        .padding(.leading, 4)

                                    LoadFailedView(message: message) {
                                        vm.retryHoroscope()
                                    }
                                    .padding(20)
                                    .backgroundWithShape(12, .cardBackground, showsStroke: true)
                                }
                                .padding(.top, 15)
                            } else {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 15)
                            }

                            Button(action: compatibilityButton) {
                                HStack {
                                    Text("Проверить совместимость")
                                        .font(Adaptive.size(.system(size: 18), .system(size: 19), .title3))
                                        .bold()
                                        .foregroundStyle(.white)

                                    Spacer()

                                    sparkImageWithBackground(Adaptive.size(.medium, .large, .large), .white)
                                }
                                .padding(.horizontal, 7)
                                .padding(Adaptive.size(18, 18, 20))
                                .frame(maxWidth: .infinity)
                                .background(LinearGradient(colors: [.purple, .blue],
                                                           startPoint: .leading,
                                                           endPoint: .trailing))
                                .clipShape(.rect(cornerRadius: 12))
                            }

                            VStack(alignment: .leading, spacing: Adaptive.size(10, 10, 12)) {
                                headerText(title: "Проверьте себя",
                                           buttonTitle: "Все тесты") {
                                    vm.showAllTests()
                                }
                                .disabled(!vm.allowsAIAnalysis)

                                ForEach(PersonalityTestTypes.allCases.prefix(3), id: \.self) { test in
                                    TestCellView(type: test,
                                                 hasChosenTest: vm.isSelected(test)) {
                                        vm.toggleTestSelection(test)
                                    } onTapHandler: {
                                        vm.showTestDetails(test)
                                    }
                                }
                                .disabled(!vm.allowsAIAnalysis)

                                ClassicButton(title: "Проверить себя") {
                                    vm.makePersonalityTest()
                                }
                                .disabled(!vm.allowsAIAnalysis)
                                .padding(.top, 10)
                            }
                            .blur(radius: !vm.allowsAIAnalysis ? 5 : 0)
                            .padding(.top, 15)
                            .overlay {
                                if !vm.allowsAIAnalysis {
                                    AIConsentLock(
                                        title: "Разрешите анализ с помощью AI для прохождения тестов",
                                        onAllow: aiConsentButton)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .bottomAreaPadding(50)
                    .scrollIndicators(.hidden)
                    .refreshable { await vm.refresh() }
                }
                .localizedNavigationTitle("Главная")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: HomeRoutes.self) { destination in
                    destinationView(destination)
                }
            }
            .opacity(vm.showsLoadingScreen ? 0 : 1)

            LoadingView(title: vm.isLoading ? vm.loadingTitle : "Загружаем информацию",
                        isPresented: vm.showsLoadingScreen)
                .opacity(vm.showsLoadingScreen ? 1 : 0)
        }
        .animation(.easeInOut(duration: 0.35), value: vm.showsLoadingScreen)
        .onAppear {
            Task { await vm.refreshIfNeeded() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await vm.refreshIfNeeded() }
            }
        }
        .alert(vm.alertMessage, isPresented: $vm.showAlert) {
            Button("OK", role: .cancel) {}
        }
        .sheet(item: $vm.emailConfirmation) { confirmation in
            EmailConfirmationSheetView(vm: confirmation)
        }
    }
}

extension HomeView {
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
            case .aiConsent:
                AIConsentView(allow: vm.allowAIConsent,
                              decline: vm.declineAIConsent)
        }
    }
    
    private func headerText(title: LocalizedStringResource,
                            buttonTitle: LocalizedStringResource,
                            onTapHandler: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .fontWeight(.semibold)
                .padding(.leading, 4)

            Spacer()

            Button(action: onTapHandler) {
                Text(buttonTitle)
                    .foregroundStyle(.tint)
                    .fontWeight(.medium)
            }
        }
        .font(Adaptive.size(.system(size: 15), .callout, .default))
    }

    private func sparkImageWithBackground(_ size: Image.Scale, _ color: Color) -> some View {
        Image(systemName: "sparkles")
            .imageScale(size)
            .foregroundStyle(color)
            .padding(8)
            .background(Color.fieldBackground.opacity(0.15))
            .clipShape(.circle)
    }
}

#Preview {
    let services = PreviewServices()
    HomeView(vm: HomeViewModel(authService: services.authService,
                               contentService: services.contentService)) {

    } aiConsentButton: {

    }
}
