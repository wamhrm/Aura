//
//  AIConsentView.swift
//  Aura
//
//  Created by wamhrm on 13/11/2026.
//

import SwiftUI

struct AIConsentView: View {
    let allow: () -> Void
    let decline: () -> Void

    var body: some View {
        ZStack {
            BackgroundView()

            VStack(spacing: 20) {
                AIConsentContentView()

                VStack(spacing: 5) {
                    ClassicButton(title: AppLanguage.text("Разрешить")) {
                        allow()
                    }

                    Button {
                        decline()
                    } label: {
                        Text(AppLanguage.text("Не сейчас"))
                            .font(.system(size: Adaptive.size(14, 15, 15)))
                            .foregroundStyle(.deepGray)
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .padding(.bottom)
                .onboardingViewModifier()
            }
        }
    }
}

#Preview {
    AIConsentView() {
        
    } decline: {
        
    }
}
