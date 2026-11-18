//
//  ProfileInfoComponents.swift
//  Aura
//
//  Created by wamhrm on 27.10.2026.
//

import SwiftUI

struct PsychotypeSectionsView: View {
    @Binding var profileInfo: ProfileInfoModel

    var body: some View {
        ProfileInfoSection(title: AppLanguage.text("Темперамент")) {
            FlowLayout() {
                ProfileInfoOptionView(type: .introvert, selection: $profileInfo.socialType)
                ProfileInfoOptionView(type: .ambivert, selection: $profileInfo.socialType)
                ProfileInfoOptionView(type: .extrovert, selection: $profileInfo.socialType)
            }
        }

        ProfileInfoSection(title: AppLanguage.text("Стиль в конфликте")) {
            FlowLayout() {
                ProfileInfoOptionView(type: .mediator, selection: $profileInfo.conflictStyle)
                ProfileInfoOptionView(type: .direct, selection: $profileInfo.conflictStyle)
                ProfileInfoOptionView(type: .avoider, selection: $profileInfo.conflictStyle)
            }
        }

        ProfileInfoSection(title: AppLanguage.text("Эмоциональная основа")) {
            FlowLayout() {
                ProfileInfoOptionView(type: .logic, selection: $profileInfo.emotionalCore)
                ProfileInfoOptionView(type: .intuitive, selection: $profileInfo.emotionalCore)
            }
        }

        ProfileInfoSection(title: AppLanguage.text("Вы чаще")) {
            FlowLayout() {
                ProfileInfoOptionView(type: .planner, selection: $profileInfo.decisionStyle)
                ProfileInfoOptionView(type: .spontaneous, selection: $profileInfo.decisionStyle)
                ProfileInfoOptionView(type: .procrastinator, selection: $profileInfo.decisionStyle)
            }
        }

        ProfileInfoSection(title: AppLanguage.text("Приоритет")) {
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
                .font(Adaptive.size(.system(size: 15), .callout, .default))
                .foregroundStyle(.deepGray)
                .fontWeight(.medium)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .backgroundWithShape(12, .cardBackground, showsStroke: false)
    }
}

struct ProfileInfoOptionView: View {
    let type: ProfileInfoOption
    @Binding var selection: String?
    
    private var isSelected: Bool {
        selection == type.rawValue
    }

    var body: some View {
        HStack {
            Text(type.icon)
                .font(Adaptive.size(.footnote, .system(size: 14), .system(size: 15)))

            Text(type.title)
                .font(Adaptive.size(.footnote, .system(size: 14), .system(size: 14)))
                .foregroundStyle(isSelected ? .white : .primaryText)
                .bold()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(Color.fieldBackground))
        .clipShape(.rect(cornerRadius: 10))
        .onTapGesture { selection = type.rawValue }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

struct FlowLayout: Layout {
    private let spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews,
                      cache: inout ()) -> CGSize {
        layout(subviews: subviews, width: proposal.width).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        let frames = layout(subviews: subviews, width: bounds.width).frames
        for (view, frame) in zip(subviews, frames) {
            view.place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                       proposal: ProposedViewSize(frame.size))
        }
    }

    private func layout(subviews: Subviews, width: CGFloat?) -> (size: CGSize, frames: [CGRect]) {
        let availableWidth = width.flatMap { $0.isFinite ? $0 : nil }
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, contentWidth: CGFloat = 0
        var frames: [CGRect] = []
        for view in subviews {
            var size = view.sizeThatFits(.unspecified)
            if let availableWidth, size.width > availableWidth {
                size = view.sizeThatFits(ProposedViewSize(width: availableWidth, height: nil))
            }

            if let availableWidth, x > 0, x + size.width > availableWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            contentWidth = max(contentWidth, x + size.width)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return (CGSize(width: availableWidth ?? contentWidth, height: y + rowHeight), frames)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            ProfileInfoSection(title: AppLanguage.text("Ваш пол")) {
                HStack {
                    ProfileInfoOptionView(type: .man, selection: .constant("man"))
                    ProfileInfoOptionView(type: .woman, selection: .constant(nil))
                }
            }

            PsychotypeSectionsView(profileInfo: .constant(ProfileInfoModel()))
        }
        .padding(.horizontal)
    }
}
