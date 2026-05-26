//
//  View+Extensions.swift
//  Aura
//
//  Created by ddorsat on 21.05.2026.
//

import Foundation
import SwiftUI

extension View {
    func bottomAreaPadding() -> some View {
        self
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 50) }
    }
    
    func backgroundWithShape(_ amount: CGFloat, _ color: Color, _ stroke: Bool) -> some View {
        self
            .background(RoundedRectangle(cornerRadius: amount) .fill(color))
            .overlay(RoundedRectangle(cornerRadius: amount) .stroke(.black, lineWidth: stroke ? 0.2 : 0))
            .clipShape(RoundedRectangle(cornerRadius: amount))
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
            .background(Color(.systemGray6).opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12) .stroke(Color(.systemGray6), lineWidth: 1))
            .padding(.top, 5)
    }
    
    func compatibilityResultZodiacsModifier() -> some View {
        self
            .font(Components.isRegular(.callout, .default))
            .padding(Components.isRegular(10, 12))
            .background(.deepBlue.opacity(0.25))
            .clipShape(Circle())
    }
    
    private func sparkleImage(_ size: Image.Scale, _ padding: CGFloat) -> some View {
        Image(systemName: "sparkles")
            .imageScale(size)
            .padding(.top, 10)
            .foregroundStyle(.white)
            .padding(padding)
    }
}
