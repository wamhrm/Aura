//
//  View+Extensions.swift
//  Aura
//
//  Created by wamhrm on 21.05.2026.
//

import Foundation
import SwiftUI
import UIKit

extension View {
    func bottomAreaPadding(_ value: CGFloat) -> some View {
        self
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: value) }
    }
    
    func backgroundWithShape(_ amount: CGFloat, _ color: Color, _ stroke: Bool) -> some View {
        self
            .background(color, in: .rect(cornerRadius: amount))
            .overlay(RoundedRectangle(cornerRadius: amount).stroke(.cardStroke, lineWidth: stroke ? 0.2 : 0))
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
        modifier(CompatibilityResultZodiacsModifier())
    }

    func zodiacSignModifier() -> some View {
        self
            .font(Adaptive.size(.title2, .system(size: 24)))
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

    /// Place this outside `NavigationStack`. Route changes under the cover do not slide.
    func loadingCover(isPresented: Bool, title: String) -> some View {
        ZStack {
            self
                .transaction { transaction in
                    if isPresented {
                        transaction.disablesAnimations = true
                    }
                }
                .opacity(isPresented ? 0 : 1)
                .allowsHitTesting(!isPresented)

            ZStack {
                BackgroundView()
                LoadingView(title: title)
            }
            .opacity(isPresented ? 1 : 0)
            .allowsHitTesting(isPresented)
        }
        .animation(.easeInOut(duration: CoveredTransition.appearSeconds), value: isPresented)
    }
    
    private func sparkleImage(_ size: Image.Scale, _ padding: CGFloat) -> some View {
        Image(systemName: "sparkles")
            .imageScale(size)
            .padding(.top, 10)
            .foregroundStyle(.white)
            .padding(padding)
    }
}

private struct CompatibilityResultZodiacsModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
            .font(Adaptive.size(.callout, .default))
            .padding(Adaptive.size(10, 12))
            .background(.tint.opacity(0.25))
            .clipShape(.circle)
    }
}

@MainActor
enum CoveredTransition {
    static let appearSeconds: TimeInterval = 0.35
    static let settleDuration: Duration = .milliseconds(50)

    /// Runs `operation` under an already visible cover, then `commit`.
    /// `leaveCover` returns true when this screen is about to be replaced and the cover must stay.
    static func run<T>(hide: () -> Void,
                       operation: () async throws -> T,
                       commit: (T) -> Void = { _ in },
                       leaveCover: () -> Bool = { false }) async throws {
        let started = ContinuousClock.now

        do {
            let result = try await operation()
            try await Task.sleep(until: started.advanced(by: .seconds(appearSeconds)),
                                 clock: .continuous)
            try Task.checkCancellation()
            commit(result)
            guard !leaveCover() else { return }
            try await Task.sleep(for: settleDuration)
            try Task.checkCancellation()
        } catch {
            hide()
            throw error
        }

        hide()
    }
}
