//
//  AIConsentView.swift
//  Aura
//
//  Created by wamhrm on 23.10.2026.
//

import SwiftUI

struct AIConsentView: View {
    var title: String = "Разрешить"
    var isDisabled = false
    let allow: () -> Void
    let decline: () -> Void
    var back: (() -> Void)? = nil

    var body: some View {
        ZStack {
            BackgroundView()

            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    AIConsentContentView()

                    VStack(spacing: 5) {
                        ClassicButton(title: title) {
                            allow()
                        }

                        Button {
                            decline()
                        } label: {
                            Text("Не сейчас")
                                .font(.system(size: Adaptive.size(14, 15)))
                                .foregroundStyle(.deepGray)
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .padding(.bottom)
                    .disabled(isDisabled)
                    .onboardingViewModifier()
                }
            }
            .toolbar {
                toolbarItem()
            }
        }
    }
}

extension AIConsentView {
    @ToolbarContentBuilder
    private func toolbarItem() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                (back ?? decline)()
            } label: {
                Image(systemName: "chevron.left")
            }
        }
    }
}

#Preview {
    NavigationStack {
        AIConsentView(allow: {}, decline: {})
    }
}
