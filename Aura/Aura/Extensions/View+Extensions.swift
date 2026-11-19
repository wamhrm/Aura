//
//  View+Extensions.swift
//  Aura
//
//  Created by wamhrm on 21.05.2026.
//

import SwiftUI
import UIKit

extension View {
    func localizedNavigationTitle(_ title: LocalizedStringResource) -> some View {
        modifier(LocalizedNavigationTitle(title: title))
    }

    func bottomAreaPadding(_ value: CGFloat) -> some View {
        self
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: value) }
    }
    
    func backgroundWithShape(_ amount: CGFloat, _ color: Color, showsStroke: Bool) -> some View {
        self
            .background(color, in: .rect(cornerRadius: amount))
            .overlay(RoundedRectangle(cornerRadius: amount).stroke(.cardStroke, lineWidth: showsStroke ? 0.2 : 0))
            .clipShape(.rect(cornerRadius: amount))
            .shadow(color: .gray.opacity(0.1), radius: 3)
    }
    
    func addSparkles() -> some View {
        self
            .overlay(alignment: .topLeading) {
                sparkleImage(.medium, 30)
                    .opacity(0.55)
            }
            .overlay(alignment: .topTrailing) {
                sparkleImage(.small, 70)
                    .padding(.trailing)
                    .opacity(0.35)
            }
            .overlay(alignment: .bottomLeading) {
                sparkleImage(.medium, 50)
                    .opacity(0.75)
            }
            .overlay(alignment: .topTrailing) {
                sparkleImage(.large, 30)
                    .opacity(0.9)
            }
            .overlay(alignment: .bottomTrailing) {
                sparkleImage(.small, 30)
                    .opacity(0.75)
                    .padding(.trailing)
            }
    }
    
    func testTopicsModifier() -> some View {
        self
            .padding(10)
            .background(Color.fieldBackground.opacity(0.55))
            .clipShape(.rect(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.fieldBackground, lineWidth: 1))
            .padding(.top, 5)
    }
    
    func onboardingViewModifier() -> some View {
        self
            .padding(.horizontal)
            .padding(.bottom, 10)
    }
    
    func compatibilityResultZodiacsModifier() -> some View {
        self
            .font(Adaptive.size(.callout, .default, .default))
            .padding(Adaptive.size(10, 10, 12))
            .background(.tint.opacity(0.25))
            .clipShape(.circle)
    }

    func zodiacSignModifier() -> some View {
        self
            .font(Adaptive.size(.title2, .system(size: 23), .system(size: 24)))
            .padding(10)
            .background(LinearGradient(colors: [.softPurple,
                                                .idealPartnerType1],
                                       startPoint: .top,
                                       endPoint: .bottom))
            .overlay(Circle().stroke(.zodiacStroke, lineWidth: 2))
            .clipShape(.circle)
            .shadow(radius: 1)
    }
    
    func dismissKeyboardOnTap() -> some View {
        simultaneousGesture(TapGesture().onEnded { _ in
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                            to: nil,
                                            from: nil,
                                            for: nil)
            }
        )
    }

    private func sparkleImage(_ size: Image.Scale, _ padding: CGFloat) -> some View {
        Image(systemName: "sparkles")
            .imageScale(size)
            .padding(.top, 10)
            .foregroundStyle(.white)
            .padding(padding)
    }
}

private struct LocalizedNavigationTitle: ViewModifier {
    @Environment(\.locale) private var locale
    let title: LocalizedStringResource

    func body(content: Content) -> some View {
        var title = title
        title.locale = locale
        return content.navigationTitle(String(localized: title))
    }
}
