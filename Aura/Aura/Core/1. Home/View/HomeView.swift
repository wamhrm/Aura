//
//  HomeView.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var vm: HomeViewModel
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

    private let authService: AuthServiceProtocol
    private let compatibilityButton: () -> Void
    private let profileButton: () -> Void

    init(vm: HomeViewModel,
         authService: any AuthServiceProtocol,
         compatibilityButton: @escaping () -> Void,
         profileButton: @escaping () -> Void) {
        self.vm = vm
        self.authService = authService
        self.compatibilityButton = compatibilityButton
        self.profileButton = profileButton
    }

    var body: some View {
        NavigationStack(path: $vm.homeRoutes) {
            ZStack {
                Components.backgroundColor()

                if vm.isLoadingScreen {
                    ProgressView()
                } else {
                    if vm.isServerWakingUp {
                        Components.serverWakingUpView(vm.isServerWakingUp)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 15) {
                                HStack(spacing: 15) {
                                    Components.logoImage(32)

                                    Text(vm.userName.isEmpty ? "Добро пожаловать" : "Здравствуйте, \(vm.userName.capitalized)")
                                        .font(Components.displaySize(.callout, .default))
                                        .fontWeight(.semibold)
                                        .fontDesign(.monospaced)

                                    Spacer()
                                }

                                if vm.hasProfileInfo {
                                    VStack(alignment: .leading, spacing: 15) {
                                        Text("ИНСАЙТ ДНЯ")
                                            .font(Components.displaySize(.callout, .default))
                                            .fontWeight(.heavy)

                                        Text(vm.dailyInsightHandler)
                                            .font(.system(size: Components.displaySize(14, 15))).italic()
                                            .fontWeight(.medium)
                                    }
                                    .foregroundStyle(.white)
                                    .padding(20)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Components.handleAccentColor(accentColor).opacity(0.85))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))

                                    if let horoscope = vm.horoscope {
                                        VStack(alignment: .leading, spacing: 10) {
                                            headerText("Гороскоп на неделю", "Читать") {
                                                vm.homeRoutes.append(.horoscopeDetails)
                                            }

                                            HoroscopeCellView(horoscope: horoscope) {
                                                vm.homeRoutes.append(.horoscopeDetails)
                                            }
                                        }
                                        .padding(.top, 15)
                                    }
                                }

                                if !vm.hasProfileInfo {
                                    completeYourProfile(vm.isSignedIn) {
                                        if vm.isSignedIn {
                                            vm.homeRoutes.append(.addProfileInfo)
                                        } else {
                                            profileButton()
                                        }
                                    }
                                }

                                Button {
                                    compatibilityButton()
                                } label: {
                                    HStack {
                                        Text("Проверить совместимость")
                                            .font(Components.displaySize(.system(size: 18), .title3))
                                            .bold()
                                            .foregroundStyle(.white)
                                        
                                        Spacer()

                                        sparkImageWithBackground(Components.displaySize(.medium, .large), .white)
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
                                        vm.homeRoutes.append(.allTests)
                                    }

                                    ForEach(PersonalityTestTypes.allCases[0...2], id: \.self) { test in
                                        TestCellView(type: test,
                                                     hasChosenTest: Binding(
                                                        get: { vm.selectedTests.contains(test) },
                                                        set: { _ in })) {
                                                            vm.toggleTestSelection(test)
                                                        } onTapHandler: {
                                                            vm.homeRoutes.append(.testDetails(test))
                                                        }
                                    }
                                    .disabled(!vm.hasProfileInfo)

                                    Components.classicButton(vm.isLoading ? "Готовим результат..." : "Проверить себя") {
                                        vm.makePersonalityTest()
                                    }
                                    .disabled(vm.isLoading || !vm.hasProfileInfo)
                                    .padding(.top, 10)
                                }
                                .blur(radius: !vm.hasProfileInfo ? 5 : 0)
                                .padding(.top, 15)
                                .overlay {
                                    if vm.userName.isEmpty {
                                        Components.completeYourProfileLock("Войдите или зарегистрируйтесь для прохождения тестов")
                                    } else if !vm.hasProfileInfo {
                                        Components.completeYourProfileLock("Заполните свой профиль для прохождения тестов")
                                    }
                                }
                            }
                            .disabled(vm.isLoading)
                            .padding(.horizontal)
                        }
                        .bottomAreaPadding(50)
                        .scrollIndicators(.hidden)
                        .alert(vm.alertMessage, isPresented: $vm.showAlert) {
                            Button("OK", role: .cancel) {}
                        }
                    }
                }
            }
            .navigationTitle("Главная")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: HomeRoutes.self) { destination in
                destinationView(destination)
            }
            .animation(.easeInOut(duration: 0.25), value: vm.isServerWakingUp)
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
                    .foregroundStyle(Components.handleAccentColor(accentColor))
                    .fontWeight(.medium)
            }
        }
        .font(Components.displaySize(.system(size: 15), .default))
    }

    @ViewBuilder
    private func destinationView(_ route: HomeRoutes) -> some View {
        switch route {
            case .addProfileInfo:
                AddProfileInfoView(vm: vm)
            case .horoscopeDetails:
                if let horoscope = vm.horoscope {
                    HoroscopeDetailsView(horoscope: horoscope)
                }
            case .allTests:
                AllTestsView(vm: vm) { test in
                    vm.homeRoutes.append(.testDetails(test))
                }
            case .testDetails(let test):
                TestDetailsView(type: test, isSelected: vm.selectedTests.contains(test)) {
                    vm.toggleTestSelection(test)
                }
            case .testResults:
                if let result = vm.personalityResult {
                    PersonalityResultView(result: result)
                }
        }
    }

    private func completeYourProfile(_ isSignedIn: Bool,
                                     _ addProfileInfo: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: Components.displaySize(10, 12)) {
            HStack {
                Text(isSignedIn ? "Заполните свой профиль" : "Войдите или зарегистрируйтесь, чтобы заполнить свой профиль")
                    .font(Components.displaySize(.default, .system(size: 19)))
                    .bold()
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }

            Text(isSignedIn ? "Расскажите о себе, чтобы получить детальный разбор вашего астрологического профиля" : "Вы можете рассказать о себе, чтобы получить детальный разбор вашего астрологического профиля")
                .font(Components.displaySize(.footnote, .system(size: 15)))
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .padding(.bottom, 13)

            Button {
                addProfileInfo()
            } label: {
                Text(isSignedIn ? "Заполнить информацию" : "Войти или зарегистрироваться")
                    .font(Components.displaySize(.system(size: 15), .default))
                    .foregroundStyle(Color(red: 0.42, green: 0.27, blue: 0.93))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [Color(red: 0.42,
                                                  green: 0.27,
                                                  blue: 0.93),
                                            Color(red: 0.62,
                                                  green: 0.33,
                                                  blue: 0.95)],
                                   startPoint: .leading,
                                   endPoint: .trailing))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
    let authService = AuthService()
    let contentService = ContentService()

    HomeView(vm: HomeViewModel(authService: authService,
                               contentService: contentService),
             authService: authService) {

    } profileButton: {

    }
}
