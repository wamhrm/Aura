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
                VStack(alignment: .leading, spacing: 30) {
                    Text(vm.subtitle)
                        .font(Adaptive.size(.footnote, .system(size: 14), .system(size: 15)))
                        .foregroundStyle(.secondary)

                    if vm.showsCodeEntry {
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
                        .disabled(vm.isLoading)
                    }

                    Spacer()
                }
                .animation(nil, value: vm.showsCodeEntry)
                .opacity(vm.showsCodeEntry && vm.isLoading ? 0 : 1)

                ZStack {
                    BackgroundView()
                    LoadingView(title: vm.loadingTitle,
                                isPresented: vm.showsCodeEntry && vm.isLoading)
                }
                .opacity(vm.showsCodeEntry && vm.isLoading ? 1 : 0)
            }
            .animation(.easeInOut(duration: 0.35), value: vm.showsCodeEntry && vm.isLoading)
            .padding(.horizontal)
            .localizedNavigationTitle("Подтвердите почту")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarItem()
            }
            .alert(vm.alertMessage, isPresented: vm.alertBinding) {
                Button("OK", role: .cancel) {}
            }
        }
        .presentationDetents([.height(vm.sheetHeight)])
        .animation(.easeInOut(duration: 0.25), value: vm.showsCodeEntry)
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
    EmailConfirmationSheetView(vm: EmailConfirmationViewModel(authService: AuthService.preview(),
                                                              email: "test@test.com"))
}
