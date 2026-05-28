//
//  AddProfileInfoView.swift
//  Aura
//
//  Created by ddorsat on 06.05.2026.
//

import SwiftUI
import UIKit

struct AddProfileInfoView: View {
    @ObservedObject var vm: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

    var body: some View {
        ZStack {
            Components.backgroundColor()

            if vm.isServerWakingUp {
                Components.serverWakingUpView(vm.isServerWakingUp)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        section("Ваш пол") {
                            HStack {
                                option(.man, $vm.profileInfo.gender)
                                option(.woman, $vm.profileInfo.gender)
                            }
                        }

                        section("Дата рождения") {
                            VStack(spacing: 10) {
                                CompatibilityDateOfBirthView(title: "День/Месяц/Год",
                                                             text: $vm.profileInfo.dateOfBirth,
                                                             isTime: false)

                                CompatibilityDateOfBirthView(title: "Время (необязательно)",
                                                             text: $vm.profileInfo.birthTime,
                                                             isTime: true)
                            }
                        }

                        section("Темперамент") {
                            FlowLayout() {
                                option(.introvert, $vm.profileInfo.socialType)
                                option(.ambivert, $vm.profileInfo.socialType)
                                option(.extrovert, $vm.profileInfo.socialType)
                            }
                        }

                        section("Стиль в конфликте") {
                            FlowLayout() {
                                option(.mediator, $vm.profileInfo.conflictStyle)
                                option(.direct, $vm.profileInfo.conflictStyle)
                                option(.avoider, $vm.profileInfo.conflictStyle)
                            }
                        }

                        section("Эмоциональная основа") {
                            FlowLayout() {
                                option(.logic, $vm.profileInfo.emotionalCore)
                                option(.intuitive, $vm.profileInfo.emotionalCore)
                            }
                        }

                        section("Вы чаще") {
                            FlowLayout() {
                                option(.planner, $vm.profileInfo.decisionStyle)
                                option(.spontaneous, $vm.profileInfo.decisionStyle)
                                option(.procrastinator, $vm.profileInfo.decisionStyle)
                            }
                        }

                        section("Приоритет") {
                            FlowLayout() {
                                option(.stability, $vm.profileInfo.coreFocus)
                                option(.growth, $vm.profileInfo.coreFocus)
                                option(.peace, $vm.profileInfo.coreFocus)
                            }
                        }

                        Components.classicButton(vm.isLoading ? "Сохраняем..." : "Готово") {
                            vm.saveProfileInfo {
                                dismiss()
                            }
                        }
                        .padding(.top, 5)
                        .disabled(vm.isLoading)
                    }
                    .disabled(vm.isLoading)
                    .padding(.horizontal)
                }
                .bottomAreaPadding(50)
                .scrollIndicators(.hidden)
                .dismissKeyboardOnTap()
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .navigationTitle("О вас")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.25), value: vm.isServerWakingUp)
        .alert(vm.alertMessage, isPresented: $vm.showAlert) {
            Button("ОК", role: .cancel) { }
        }
    }
}

extension AddProfileInfoView {
    private func section<Content: View>(_ title: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(Components.displaySize(.system(size: 15), .default))
                .foregroundStyle(.deepGray)
                .fontWeight(.medium)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .backgroundWithShape(12, .cardBackground, false)
    }

    private func option(_ type: ProfileInfoOption, _ selection: Binding<String?>) -> some View {
        let isSelected = selection.wrappedValue == type.rawValue

        return HStack {
            Text(type.icon)
                .font(Components.displaySize(.footnote, .system(size: 15)))

            Text(type.title)
                .font(Components.displaySize(.footnote, .system(size: 14)))
                .foregroundStyle(isSelected ? .white : .primaryText)
                .bold()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Components.handleAccentColor(accentColor) : Color.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture { selection.wrappedValue = type.rawValue }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private struct FlowLayout: Layout {
        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews,
                          cache: inout ()) -> CGSize {
            let width = proposal.width ?? 0
            var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0

            for view in subviews {
                let size = view.sizeThatFits(.unspecified)

                if x + size.width > width {
                    x = 0
                    y += rowHeight + 8
                    rowHeight = 0
                }

                x += size.width + 8
                rowHeight = max(rowHeight, size.height)
            }

            return CGSize(width: width, height: y + rowHeight)
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                           subviews: Subviews, cache: inout ()) {
            var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0

            for view in subviews {
                let size = view.sizeThatFits(.unspecified)

                if x + size.width > bounds.maxX {
                    x = bounds.minX
                    y += rowHeight + 8
                    rowHeight = 0
                }

                view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))

                x += size.width + 8
                rowHeight = max(rowHeight, size.height)
            }
        }
    }
}

enum ProfileInfoOption: String, CaseIterable {
    case man
    case woman
    case introvert
    case ambivert
    case extrovert
    case mediator
    case direct
    case avoider
    case logic
    case intuitive
    case planner
    case spontaneous
    case procrastinator
    case stability
    case growth
    case peace

    var title: String {
        switch self {
            case .man: return "Мужской"
            case .woman: return "Женский"
            case .introvert: return "Интроверт"
            case .ambivert: return "Амбиверт"
            case .extrovert: return "Экстраверт"
            case .mediator: return "Миротворец"
            case .direct: return "Прямой"
            case .avoider: return "Избегающий"
            case .logic: return "Рациональный"
            case .intuitive: return "Интуитивный"
            case .planner: return "Планируете"
            case .spontaneous: return "По ситуации"
            case .procrastinator: return "Откладываете"
            case .stability: return "Стабильность"
            case .growth: return "Рост"
            case .peace: return "Спокойствие"
        }
    }

    static func normalizedKey(_ stored: String?) -> String? {
        guard let stored, !stored.isEmpty else { return nil }
        if let match = Self.allCases.first(where: { $0.rawValue == stored }) {
            return match.rawValue
        }
        if let match = Self.allCases.first(where: { $0.title == stored }) {
            return match.rawValue
        }
        return stored
    }

    var icon: String {
        switch self {
            case .man: return "👱🏻‍♂️"
            case .woman: return "👩🏻"
            case .introvert: return "🌙"
            case .ambivert: return "🌗"
            case .extrovert: return "🔥"
            case .mediator: return "🤝"
            case .direct: return "⚡"
            case .avoider: return "🌫"
            case .logic: return "🧠"
            case .intuitive: return "✨"
            case .planner: return "🗂"
            case .spontaneous: return "⚡"
            case .procrastinator: return "⏳"
            case .stability: return "🛡"
            case .growth: return "🚀"
            case .peace: return "🕊"
        }
    }
}

#Preview {
    NavigationStack {
        AddProfileInfoView(vm: HomeViewModel(authService: AuthService(),
                                             contentService: ContentService()))
    }
}
