//
//  CompatibilityView.swift
//  Aura
//
//  Created by ddorsat on 18.05.2026.
//

import SwiftUI

struct CompatibilityView: View {
    @ObservedObject var vm: CompatibilityViewModel
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

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
                                        .font(Components.displaySize(.callout, .default))
                                        .foregroundStyle(Components.handleAccentColor(accentColor))
                                        .fontWeight(.semibold)
                                        .padding(Components.displaySize(7, 9))
                                        .background(.capsuleBackground)
                                        .clipShape(Circle())

                                    Text("Детали партнера")
                                        .font(Components.displaySize(.system(size: 15), .default))
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
                                            isTime: false) {
                                                vm.showInvalidDateOfBirthday()
                                            }

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
                            .backgroundWithShape(12, .cardBackground, true)

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
                                            .foregroundStyle(Components.handleAccentColor(accentColor))
                                            .fontWeight(.medium)
                                    }
                                }
                                .font(Components.displaySize(.system(size: 15), .default))

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
                    .dismissKeyboardOnTap()
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .bottomAreaPadding(50)
            .navigationTitle("Узнать совместимость")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: CompatibilityRoutes.self) { destination in
                destinationView(destination)
            }
            .animation(.easeInOut(duration: 0.25), value: vm.isServerWakingUp)
            .alert(vm.alertMessage, isPresented: $vm.showAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }
}

extension CompatibilityView {
    private func headerText(_ title: String) -> some View {
        Text(title)
            .font(Components.displaySize(.footnote, .system(size: 14)))
            .foregroundStyle(.deepGray)
            .fontWeight(.medium)
    }

    private func headerView() -> some View {
        VStack(alignment: .center, spacing: 7) {
            Image(systemName: "heart")
                .font(Components.displaySize(.title2, .title3))
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(15)
                .background(LinearGradient(colors: [.purple, .softPurple],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing))
                .clipShape(Circle())
                .padding(.vertical, 12)

            Text("Анализ партнера")
                .font(Components.displaySize(.default, .title3))
                .bold()

            Text("Введите информацию о партнере")
                .font(Components.displaySize(.system(size: 14), .callout))
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
        @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

        let onTapHandler: (T) -> Void

        init(selected: T = T.allCases.first!, onTapHandler: @escaping (T) -> Void) {
            self._selected = State(initialValue: selected)
            self.onTapHandler = onTapHandler
        }

        var body: some View {
            HStack(spacing: 12) {
                ForEach(Array(T.allCases), id: \.self) { item in
                    Button {
                        selected = item
                        onTapHandler(item)
                    } label: {
                        Text(item.rawValue)
                            .font(Components.displaySize(.footnote, .system(size: 14)))
                            .foregroundStyle(selected == item ? .white : .deepGray)
                            .bold()
                            .padding(.vertical, Components.displaySize(10, 11))
                            .padding(.horizontal, Components.displaySize(20, 21))
                            .background(selected == item ? Components.handleAccentColor(accentColor) : .clear)
                            .overlay(RoundedRectangle(cornerRadius: 10) .stroke(.gray, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }
}

fileprivate enum CompatibilityButtons {
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
