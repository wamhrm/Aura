//
//  HomeView.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var vm: HomeViewModel
    
    private let authService: AuthServiceProtocol
    private let psychologyService: PsychologyServiceProtocol
    let compatibilityButton: () -> Void
    let profileButton: () -> Void

    init(vm: HomeViewModel,
         authService: any AuthServiceProtocol,
         psychologyService: any PsychologyServiceProtocol,
         compatibilityButton: @escaping () -> Void,
         profileButton: @escaping () -> Void) {
        self.vm = vm
        self.authService = authService
        self.psychologyService = psychologyService
        self.compatibilityButton = compatibilityButton
        self.profileButton = profileButton
    }

    var body: some View {
        NavigationStack(path: $vm.homeRoutes) {
            ZStack {
                Components.backgroundColor()

                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack(spacing: 15) {
                            Components.logoImage(35)

                            Text(vm.userName.isEmpty ? "Здравствуйте" : "Здравствуйте, \(vm.userName)")
                                .fontWeight(.semibold)
                                .fontDesign(.monospaced)

                            Spacer()
                        }

                        if vm.hasProfileInfo {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("ИНСАЙТ ДНЯ")
                                    .fontWeight(.heavy)

                                Text("Сегодня лучше вести спокойные беседы, чем давить эмоционально")
                                    .font(.callout)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.white)
                            .padding(22)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.softPurple)
                            .clipShape(RoundedRectangle(cornerRadius: 15))

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
                                vm.homeRoutes.append(.addProfileInfo)
                            }
                        }

                        Button {
                            compatibilityButton()
                        } label: {
                            HStack {
                                Text("Проверить совместимость")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.white)
                                    .lineSpacing(8)

                                Spacer()

                                Components.sparkImageWithBackground(.large, .white)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity)
                            .background(LinearGradient(colors: [.purple, .blue],
                                                       startPoint: .leading,
                                                       endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 15))
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

                            Components.classicButton("Проверить себя") {
                                vm.makePersonalityTest()
                            }
                            .disabled(vm.isLoading)
                            .padding(.top, 10)

                            if vm.isLoading {
                                ProgressView("Готовим результат")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .blur(radius: !vm.hasProfileInfo ? 5 : 0)
                        .padding(.top, 15)
                        .overlay {
                            if !vm.hasProfileInfo {
                                Components.completeYourProfileLock("Заполните свой профиль для прохождения тестов")
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .navigationTitle("Главная")
                .navigationBarTitleDisplayMode(.inline)
                .scrollIndicators(.hidden)
                .bottomAreaPadding()
                .navigationDestination(for: HomeRoutes.self) { destination in
                    destinationView(destination)
                }
            }
        }
        .alert(vm.errorMessage, isPresented: $vm.showError) {
            Button("OK", role: .cancel) {}
        }
    }
}

extension HomeView {
    private func headerText(_ title: String, _ buttonTitle: String,
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
                    .foregroundStyle(.blue)
                    .fontWeight(.medium)
            }
        }
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
    
    private func completeYourProfile(_ isSignedIn: Bool, _ completion: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 25) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(isSignedIn ? "Заполните свой профиль" : "Войдите или зарегистрируйтесь, чтобы заполнить свой профиль")
                        .font(.system(size: 20))
                        .bold()
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                Text(isSignedIn ? "Расскажите о себе, чтобы получить детальный разбор вашего астрологического профиля" : "Вы сможете рассказать о себе, чтобы получить детальный разбор вашего астрологического профиля")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            }
            
            Button {
                completion()
            } label: {
                Text(isSignedIn ? "Заполнить информацию" : "Войти или зарегистрироваться")
                    .foregroundStyle(Color(red: 0.42, green: 0.27, blue: 0.93))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
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
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
}

#Preview {
    let authService = AuthService()
    let psychologyService = PsychologyService()
    
    HomeView(vm: HomeViewModel(authService: authService,
                               psychologyService: psychologyService),
             authService: authService,
             psychologyService: psychologyService) {
        
    } profileButton: {
        
    }
}
