//
//  CompatibilityView.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import SwiftUI

struct CompatibilityView: View {
    @StateObject private var vm = CompatibilityViewModel()
    
    var body: some View {
        NavigationStack(path: $vm.compatibilityRoutes) {
            ZStack {
                Components.backgroundColor()
                
                ScrollView {
                    VStack(spacing: 25) {
                        headerView()
                        
                        VStack(alignment: .leading, spacing: 25) {
                            HStack {
                                Image(systemName: "heart")
                                    .foregroundStyle(.deepBlue)
                                    .fontWeight(.semibold)
                                    .padding(8)
                                    .background(.capsuleBackground)
                                    .clipShape(Circle())
                                
                                Text("Детали партнера")
                                    .bold()
                                
                                Spacer()
                            }
                            
                            VStack(alignment: .leading) {
                                headerText("Имя *")
                                
                                CompatibilityTextFieldView(title: "Введите имя", text: $vm.partnerName, type: .name(maxLength: 10))
                            }
                            
                            VStack(alignment: .leading) {
                                headerText("Пол *")
                                
                                SelectionButtons<CompatibilityButtons.genderOptions> { button in
                                    
                                }
                            }
                            
                            VStack(alignment: .leading) {
                                headerText("Дата рождения")
                                
                                SelectionButtons<CompatibilityButtons.birthOptions> { button in
                                    vm.exactDateOfBirth = button == .exactDate
                                }
                                .padding(.bottom, 10)
                                
                                if vm.exactDateOfBirth {
                                    CompatibilityDateOfBirthView(title: "День/Месяц/Год", text: $vm.partnerDateOfBirth, isTime: false)
                                    
                                    CompatibilityDateOfBirthView(title: "Время (необязательно)", text: $vm.partnerTimeOfBirth, isTime: true)
                                } else {
                                    CompatibilityTextFieldView(title: "Возраст (лет)", text: $vm.partnerAge, type: .age(maxAge: 100))
                                }
                            }
                        }
                        .padding(20)
                        .backgroundWithShape(15, true)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Выберите тесты")
                                    .fontWeight(.semibold)
                                    .padding(.leading, 4)
                                
                                Spacer()
                                
                                Button {
                                    vm.selectedTests = CompatibilityTestType.allCases
                                } label: {
                                    Text("Выбрать все")
                                        .foregroundStyle(.blue)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            ForEach(CompatibilityTestType.allCases, id: \.self) { test in
                                TestCellView(type: test,
                                             showSelection: true,
                                             hasChosenTest: Binding(
                                                get: { vm.selectedTests.contains(test) },
                                                set: { _ in })) {
                                    vm.toggleTestSelection(test)
                                } onTapHandler: {
                                    vm.compatibilityRoutes.append(.testDetails(test))
                                }
                            }
                            
                            Components.classicButton("Узнать совместимость") {
                                
                            }
                            .padding(.top, 10)
                        }
                    }
                    .padding(.horizontal)
                }
                .navigationTitle("Проверить совместимость")
                .navigationBarTitleDisplayMode(.inline)
                .bottomAreaPadding()
                .alert("Нельзя выбрать меньше 2 тестов", isPresented: $vm.showMinTestsAlert) {
                    Button("OK", role: .cancel) {}
                }
                .navigationDestination(for: CompatibilityRoutes.self) { destination in
                    destinationView(destination)
                }
            }
        }
    }
}

extension CompatibilityView {
    private func headerText(_ title: String) -> some View {
        Text(title)
            .foregroundStyle(.deepGray)
            .fontWeight(.medium)
            .font(.callout)
    }
    
    private func headerView() -> some View {
        VStack(alignment: .center, spacing: 5) {
            Image(systemName: "heart")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(15)
                .background(LinearGradient(colors: [.purple, .softPurple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(Circle())
                .padding(.bottom, 10)
            
            Text("Анализ партнера")
                .font(.title3)
                .bold()
            
            Text("Введите информацию о партнере")
                .foregroundStyle(.deepGray)
                .fontWeight(.medium)
        }
    }
    
    @ViewBuilder
    private func destinationView(_ route: CompatibilityRoutes) -> some View {
        switch route {
            case .testDetails(let test):
                TestDetailsView(type: test) {
                    
            }
        }
    }
}

enum CompatibilityButtons {
    enum birthOptions: String, CaseIterable {
        case exactDate = "Точная"
        case approximateDate = "Примерная"
    }
    
    enum genderOptions: String, CaseIterable {
        case male = "Мужской"
        case female = "Женский"
    }
}

#Preview {
    NavigationStack {
        CompatibilityView()
    }
}
