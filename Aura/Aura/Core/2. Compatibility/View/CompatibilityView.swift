//
//  CompatibilityView.swift
//  Aura
//
//  Created by ddorsat on 18.05.2026.
//

import SwiftUI

struct CompatibilityView: View {
    @ObservedObject var vm: CompatibilityViewModel

    var body: some View {
        NavigationStack(path: $vm.compatibilityRoutes) {
            ZStack {
                Components.backgroundColor()

                if vm.isServerWakingUp {
                    Components.serverWakingUpView(vm.isServerWakingUp)
                } else {
                    ScrollView {
                        VStack(spacing: 25) {
                            headerView()
                            
                            VStack(alignment: .leading, spacing: 25) {
                                HStack(spacing: 10) {
                                    Image(systemName: "heart")
                                        .font(Components.isRegular(.callout, .default))
                                        .foregroundStyle(.deepBlue)
                                        .fontWeight(.semibold)
                                        .padding(Components.isRegular(7, 9))
                                        .background(.capsuleBackground)
                                        .clipShape(Circle())
                                    
                                    Text("Детали партнера")
                                        .font(Components.isRegular(.system(size: 15), .system(size: 17)))
                                        .bold()
                                    
                                    Spacer()
                                }
                                
                                VStack(alignment: .leading) {
                                    headerText("Имя *")
                                    
                                    CompatibilityTextFieldView(title: "Введите имя",
                                                               text: $vm.partnerInfo.name,
                                                               type: .name(maxLength: 10))
                                }
                                
                                VStack(alignment: .leading) {
                                    headerText("Пол *")
                                    
                                    SelectionButtons<CompatibilityButtons.genderOptions> { button in
                                        vm.partnerInfo.gender = button.rawValue
                                    }
                                }
                                
                                VStack(alignment: .leading) {
                                    headerText("Дата рождения")
                                    
                                    SelectionButtons<CompatibilityButtons.birthOptions> { button in
                                        vm.partnerInfo.exactDateOfBirth = button == .exactDate
                                    }
                                    .padding(.bottom, 10)
                                    
                                    if vm.partnerInfo.exactDateOfBirth {
                                        CompatibilityDateOfBirthView(
                                            title: "День/Месяц/Год",
                                            text: $vm.partnerInfo.dateOfBirth,
                                            isTime: false)
                                        
                                        CompatibilityDateOfBirthView(
                                            title: "Время (необязательно)",
                                            text: $vm.partnerInfo.birthTime,
                                            isTime: true)
                                    } else {
                                        CompatibilityTextFieldView(title: "Возраст (лет)",
                                                                   text: $vm.partnerInfo.age,
                                                                   type: .age(maxAge: 100))
                                    }
                                }
                            }
                            .padding(20)
                            .backgroundWithShape(12, .white, true)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Выберите тесты")
                                        .fontWeight(.semibold)
                                        .padding(.leading, 4)
                                    
                                    Spacer()
                                    
                                    Button {
                                        vm.selectedTests = CompatibilityTestTypes.allCases
                                    } label: {
                                        Text("Выбрать все")
                                            .foregroundStyle(.blue)
                                            .fontWeight(.medium)
                                    }
                                }
                                .font(Components.isRegular(.system(size: 15), .system(size: 17)))
                                
                                ForEach(CompatibilityTestTypes.allCases, id: \.self) { test in
                                    TestCellView(type: test,
                                                 hasChosenTest: Binding(
                                                    get: { vm.selectedTests.contains(test) },
                                                    set: { _ in })) {
                                                        vm.toggleTestSelection(test)
                                                    } onTapHandler: {
                                                        vm.compatibilityRoutes.append(.testDetails(test))
                                                    }
                                }
                                
                                Components.classicButton(vm.isLoading ? "Готовим результат..." : "Узнать совместимость") {
                                    vm.makeCompatibilityTest()
                                }
                                .disabled(vm.isLoading)
                                .padding(.top, 10)
                            }
                        }
                        .disabled(vm.isLoading)
                        .padding(.horizontal)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .bottomAreaPadding()
            .navigationTitle("Узнать совместимость")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: CompatibilityRoutes.self) { destination in
                destinationView(destination)
            }
            .alert(vm.alertMessage, isPresented: $vm.showAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }
}

extension CompatibilityView {
    private func headerText(_ title: String) -> some View {
        Text(title)
            .font(Components.isRegular(.footnote, .callout))
            .foregroundStyle(.deepGray)
            .fontWeight(.medium)
    }

    private func headerView() -> some View {
        VStack(alignment: .center, spacing: 7) {
            Image(systemName: "heart")
                .font(Components.isRegular(.title2, .title3))
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(15)
                .background(LinearGradient(colors: [.purple, .softPurple],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing))
                .clipShape(Circle())
                .padding(.vertical, 12)

            Text("Анализ партнера")
                .font(Components.isRegular(.default, .title3))
                .bold()

            Text("Введите информацию о партнере")
                .font(Components.isRegular(.system(size: 14), .callout))
                .foregroundStyle(.deepGray)
                .fontWeight(.medium)
        }
    }

    @ViewBuilder
    private func destinationView(_ route: CompatibilityRoutes) -> some View {
        switch route {
            case .testDetails(let test):
                TestDetailsView(type: test,
                                isSelected: vm.selectedTests.contains(test)) {
                    vm.toggleTestSelection(test)
                }
            case .compatibilityResults:
                if let result = vm.compatibilityResult {
                    CompatibilityResultView(result: result)
                }
        }
    }
    
    private struct SelectionButtons<T: RawRepresentable & CaseIterable & Hashable>: View where T.RawValue == String {
        @State private var selected: T
        let onTapHandler: (T) -> Void
        
        init(selected: T = T.allCases.first!, onTapHandler: @escaping (T) -> Void) {
            self._selected = State(initialValue: selected)
            self.onTapHandler = onTapHandler
        }
        
        var body: some View {
            HStack(spacing: 15) {
                ForEach(Array(T.allCases), id: \.self) { item in
                    Button {
                        selected = item
                        onTapHandler(item)
                    } label: {
                        Text(item.rawValue)
                            .font(Components.isRegular(.footnote, .system(size: 15)))
                            .foregroundStyle(selected == item ? .white : .deepGray)
                            .bold()
                            .padding(.vertical, Components.isRegular(10, 12))
                            .padding(.horizontal, Components.isRegular(20, 22))
                            .background(selected == item ? .deepBlue : .clear)
                            .overlay(RoundedRectangle(cornerRadius: 10) .stroke(.gray, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }
}

enum CompatibilityButtons {
    enum genderOptions: String, CaseIterable {
        case male = "Мужской"
        case female = "Женский"
    }
    
    enum birthOptions: String, CaseIterable {
        case exactDate = "Точная"
        case approximateDate = "Примерная"
    }
}

#Preview {
    NavigationStack {
        CompatibilityView(vm: CompatibilityViewModel(authService: AuthService(),
                                                     contentService: ContentService()))
    }
}
