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
            BackgroundView()

            if vm.isServerWakingUp {
                ServerWakingUpView(isVisible: vm.isServerWakingUp)
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

                        ClassicButton(title: vm.isLoading ? "Сохраняем..." : "Готово") {
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
                .font(Adaptive.size(.system(size: 15), .default))
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
                .font(Adaptive.size(.footnote, .system(size: 15)))

            Text(type.title)
                .font(Adaptive.size(.footnote, .system(size: 14)))
                .foregroundStyle(isSelected ? .white : .primaryText)
                .bold()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(isSelected ? AccentColorOption.color(accentColor) : Color.fieldBackground)
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
            case .man: "Мужской"
            case .woman: "Женский"
            case .introvert: "Интроверт"
            case .ambivert: "Амбиверт"
            case .extrovert: "Экстраверт"
            case .mediator: "Миротворец"
            case .direct: "Прямой"
            case .avoider: "Избегающий"
            case .logic: "Рациональный"
            case .intuitive: "Интуитивный"
            case .planner: "Планируете"
            case .spontaneous: "По ситуации"
            case .procrastinator: "Откладываете"
            case .stability: "Стабильность"
            case .growth: "Рост"
            case .peace: "Спокойствие"
        }
    }

    var icon: String {
        switch self {
            case .man: "👱🏻‍♂️"
            case .woman: "👩🏻"
            case .introvert: "🌙"
            case .ambivert: "🌗"
            case .extrovert: "🔥"
            case .mediator: "🤝"
            case .direct: "⚡"
            case .avoider: "🌫"
            case .logic: "🧠"
            case .intuitive: "✨"
            case .planner: "🗂"
            case .spontaneous: "⚡"
            case .procrastinator: "⏳"
            case .stability: "🛡"
            case .growth: "🚀"
            case .peace: "🕊"
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
}

#Preview {
    NavigationStack {
        AddProfileInfoView(vm: HomeViewModel(authService: AuthService(),
                                             contentService: ContentService()))
    }
}
