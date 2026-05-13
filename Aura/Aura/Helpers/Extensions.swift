//
//  Extensions.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import Foundation
import SwiftUI

extension View {
    func bottomAreaPadding() -> some View {
        self
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 50) }
    }
    
    func backgroundWithShape(_ amount: CGFloat, _ stroke: Bool) -> some View {
        self
            .background(RoundedRectangle(cornerRadius: amount) .fill(.white))
            .overlay(RoundedRectangle(cornerRadius: amount) .stroke(.black, lineWidth: stroke ? 0.2 : 0))
            .clipShape(RoundedRectangle(cornerRadius: amount))
            .shadow(color: .gray.opacity(0.1), radius: 3)
    }
    
    func addSparkles() -> some View {
        self
            .overlay(alignment: .topLeading) {
                Components.sparkleImage(.medium, 30)
                    .opacity(0.55)
            }
            .overlay(alignment: .topTrailing) {
                Components.sparkleImage(.small, 70)
                    .padding(.trailing)
                    .opacity(0.35)
            }
            .overlay(alignment: .bottomLeading) {
                Components.sparkleImage(.medium, 50)
                    .opacity(0.75)
            }
            .overlay(alignment: .topTrailing) {
                Components.sparkleImage(.large, 30)
                    .opacity(0.9)
            }
            .overlay(alignment: .bottomTrailing) {
                Components.sparkleImage(.small, 30)
                    .opacity(0.75)
                    .padding(.trailing)
            }
    }
    
    func addProfileInfoCellBackground() -> some View {
        self
            .padding(15)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 15))
    }
    
    func testTopicsModifier() -> some View {
        self
            .padding(10)
            .background(Color(.systemGray6).opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10) .stroke(Color(.systemGray6), lineWidth: 1))
            .padding(.top, 5)
    }
}
