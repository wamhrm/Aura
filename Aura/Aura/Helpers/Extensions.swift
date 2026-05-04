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
    
    func backgroundWithShape(_ amount: CGFloat) -> some View {
        self
            .background(RoundedRectangle(cornerRadius: amount) .fill(.white))
            .overlay(RoundedRectangle(cornerRadius: amount) .stroke(.black, lineWidth: 0.2))
            .clipShape(RoundedRectangle(cornerRadius: amount))
            .shadow(color: .gray.opacity(0.1), radius: 3)
    }
}
