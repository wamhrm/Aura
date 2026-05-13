//
//  HomeView.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var vm: HomeViewModel
    
    init(authService: any AuthServiceProtocol) {
        _vm = StateObject(wrappedValue: HomeViewModel(authService: authService))
    }
    
    var body: some View {
        NavigationStack(path: $vm.homeRoutes) {
            ZStack {
                Components.backgroundColor()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack(spacing: 15) {
                            Components.logoImage(35)
                                
                            Text("Здравствуйте, Дмитрий")
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
                            
                            VStack(alignment: .leading, spacing: 10) {
                                headerText("Гороскоп на неделю", "Читать") {
                                    vm.homeRoutes.append(.horoscopeDetails)
                                }
                                
                                HoroscopeCellView(horoscope: .mock) {
                                    vm.homeRoutes.append(.horoscopeDetails)
                                }
                            }
                            .padding(.top, 15)
                        }
                        
                        if !vm.hasProfileInfo {
                            Components.completeYourProfile {
                                vm.homeRoutes.append(.addProfileInfo)
                            }
                        }
                        
                        Button {
                            
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
                                vm.homeRoutes.append(.tests)
                            }
                            
                            ForEach(Array(TestTypes.allCases[0...2]), id: \.self) { test in
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
                                vm.generatePersonalityAnalysis()
                            }
                            .disabled(vm.isGeneratingPersonalityAnalysis)
                            .padding(.top, 10)

                            if vm.isGeneratingPersonalityAnalysis {
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
        .alert("Нельзя выбрать меньше 2 тестов", isPresented: $vm.showMinTestsAlert) {
            Button("OK", role: .cancel) {}
        }
        .alert("Не удалось получить результат", isPresented: $vm.showPersonalityAnalysisError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.personalityAnalysisErrorMessage ?? "Попробуйте ещё раз")
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
            case .tests:
                AllTestsView(vm: vm) { test in
                    vm.homeRoutes.append(.testDetails(test))
                }
            case .testDetails(let test):
                TestDetailsView(type: test, isSelected: vm.selectedTests.contains(test)) {
                    vm.toggleTestSelection(test)
                }
            case .testResults:
                PersonalityResultsView(vm: vm)
            case .horoscopeDetails:
                HoroscopeDetailsView(horoscope: .mock)
            case .addProfileInfo:
                AddProfileInfoView(vm: vm)
        }
    }
}

#Preview {
    HomeView(authService: AuthService())
}
