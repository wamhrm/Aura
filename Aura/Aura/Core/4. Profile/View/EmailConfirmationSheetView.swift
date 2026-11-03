//
//  EmailConfirmationSheetView.swift
//  Aura
//
//  Created by wamhrm on 03.11.2026.
//

import SwiftUI

struct EmailConfirmationSheetView: View {
    @ObservedObject var vm: EmailConfirmationViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text(vm.subtitle)
                    .font(Adaptive.size(.footnote, .system(size: 15)))
                    .foregroundStyle(.secondary)

                if vm.isCodeSent {
                    OnboardingTextField(type: .code, text: $vm.code)

                    ClassicButton(title: vm.confirmButtonTitle) {
                        vm.confirm()
                    }

                    OnboardingTextButton(title: "Отправить код ещё раз") {
                        vm.sendCode()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ClassicButton(title: vm.sendCodeButtonTitle) {
                        vm.sendCode()
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .navigationTitle("Подтвердите почту")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarItem()
            }
            .alert(vm.alertMessage, isPresented: $vm.showAlert) {
                Button("OK", role: .cancel) {}
            }
        }
        .disabled(vm.isLoading)
        .presentationDetents([.height(Adaptive.size(320, 340))])
    }
}

extension EmailConfirmationSheetView {
    @ToolbarContentBuilder
    private func toolbarItem() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(role: .cancel) {
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
        }
    }
}

#Preview {
    EmailConfirmationSheetView(vm: EmailConfirmationViewModel(authService: AuthService.preview,
                                                              email: "test@test.com"))
}
