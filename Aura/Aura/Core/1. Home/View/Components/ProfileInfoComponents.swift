//
//  ProfileInfoComponents.swift
//  Aura
//
//  Created by ddorsat on 27.10.2026.
//

import SwiftUI

struct PsychotypeSectionsView: View {
    @Binding var profileInfo: ProfileInfoModel

    var body: some View {
        ProfileInfoSection(title: "Темперамент") {
            FlowLayout() {
                ProfileInfoOptionView(type: .introvert, selection: $profileInfo.socialType)
                ProfileInfoOptionView(type: .ambivert, selection: $profileInfo.socialType)
                ProfileInfoOptionView(type: .extrovert, selection: $profileInfo.socialType)
            }
        }

        ProfileInfoSection(title: "Стиль в конфликте") {
            FlowLayout() {
                ProfileInfoOptionView(type: .mediator, selection: $profileInfo.conflictStyle)
                ProfileInfoOptionView(type: .direct, selection: $profileInfo.conflictStyle)
                ProfileInfoOptionView(type: .avoider, selection: $profileInfo.conflictStyle)
            }
        }

        ProfileInfoSection(title: "Эмоциональная основа") {
            FlowLayout() {
                ProfileInfoOptionView(type: .logic, selection: $profileInfo.emotionalCore)
                ProfileInfoOptionView(type: .intuitive, selection: $profileInfo.emotionalCore)
            }
        }

        ProfileInfoSection(title: "Вы чаще") {
            FlowLayout() {
                ProfileInfoOptionView(type: .planner, selection: $profileInfo.decisionStyle)
                ProfileInfoOptionView(type: .spontaneous, selection: $profileInfo.decisionStyle)
                ProfileInfoOptionView(type: .procrastinator, selection: $profileInfo.decisionStyle)
            }
        }

        ProfileInfoSection(title: "Приоритет") {
            FlowLayout() {
                ProfileInfoOptionView(type: .stability, selection: $profileInfo.coreFocus)
                ProfileInfoOptionView(type: .growth, selection: $profileInfo.coreFocus)
                ProfileInfoOptionView(type: .peace, selection: $profileInfo.coreFocus)
            }
        }
    }
}

struct ProfileInfoSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
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
}

struct ProfileInfoOptionView: View {
    let type: ProfileInfoOption
    @Binding var selection: String?
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

    var body: some View {
        HStack {
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
        .onTapGesture { selection = type.rawValue }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

extension ProfileInfoOptionView {
    private var isSelected: Bool {
        selection == type.rawValue
    }
}

struct FlowLayout: Layout {
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
