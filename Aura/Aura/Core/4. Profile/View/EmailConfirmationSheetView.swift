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
            ZStack {
                ZStack {
                    BackgroundView()

                    VStack(alignment: .leading, spacing: 30) {
                        Text(vm.subtitle)
                            .font(Adaptive.size(.footnote, .system(size: 15)))
                            .foregroundStyle(.secondary)

                        if vm.isCodeSent {
                            VStack(spacing: 25) {
                                OnboardingTextField(text: $vm.code, type: .code)

                                ClassicButton(title: vm.confirmButtonTitle) {
                                    vm.confirm()
                                }

                                OnboardingTextButton(title: "Отправить код ещё раз") {
                                    vm.sendCode()
                                }
                                .frame(maxWidth: .infinity)
                            }
                        } else {
                            ClassicButton(title: vm.sendCodeButtonTitle) {
                                vm.sendCode()
                            }
                        }

                        Spacer(minLength: 0)
                    }
                }
                .opacity(vm.isLoading ? 0 : 1)
                .allowsHitTesting(!vm.isLoading)

                ZStack {
                    BackgroundView()

                    LoadingView(title: vm.loadingTitle)
                }
                .opacity(vm.isLoading ? 1 : 0)
                .allowsHitTesting(vm.isLoading)
            }
            .animation(.easeInOut(duration: 0.35), value: vm.isLoading)
            .padding(.horizontal)
            .navigationTitle("Подтвердите почту")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarItem()
            }
            .alert(vm.alertMessage, isPresented: $vm.showAlert) {
                Button("OK", role: .cancel) {}
            }
        }
        .presentationDetents([.height(vm.sheetHeight)])
        .animation(.easeInOut(duration: 0.25), value: vm.isSheetExtended)
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
