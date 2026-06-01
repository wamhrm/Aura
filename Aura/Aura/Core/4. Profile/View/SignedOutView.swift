//
//  SignedOutView.swift
//  Aura
//
//  Created by ddorsat on 07.05.2026.
//

import SwiftUI

struct SignedOutView: View {
    @ObservedObject var vm: ProfileViewModel

    var body: some View {
        ZStack {
            BackgroundView()

            if vm.isServerWakingUp {
                ServerWakingUpView(isVisible: vm.isServerWakingUp)
            } else {
                VStack(spacing: 100) {
                    VStack(spacing: 15) {
                        LogoImage(size: 65)

                        Text("Добро пожаловать")
                            .fontDesign(.monospaced)
                            .bold()
                    }

                    VStack(spacing: 15) {
                        SignInCreateAccountButtonView(vm: vm,
                                                      type: .signIn,
                                                      isLanding: true) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                vm.showSignIn.toggle()
                            }
                        }

                        SignInCreateAccountButtonView(vm: vm,
                                                      type: .createAccount,
                                                      isLanding: true) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                vm.showCreateAccount.toggle()
                            }
                        }
                    }
                    .padding(.bottom, 165)
                }
                .padding(.horizontal)
                .overlay {
                    overlayView()
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .animation(.easeInOut(duration: 0.25), value: vm.isServerWakingUp)
        .alert(vm.alertMessage, isPresented: $vm.showAlert) {
            Button("ОК", role: .cancel) {}
        }
    }
}

extension SignedOutView {
    @ViewBuilder
    private func overlayView() -> some View {
        if vm.showSignIn || vm.showCreateAccount {
            SignInCreateAccountView(vm: vm, type: vm.showSignIn ? .signIn : .createAccount)
        }
    }
}

#Preview {
    SignedOutView(vm: ProfileViewModel(authService: AuthService(),
                                       contentService: ContentService()))
}
