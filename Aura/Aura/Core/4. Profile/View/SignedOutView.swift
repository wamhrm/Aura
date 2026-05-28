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
            Components.backgroundColor()

            if vm.isServerWakingUp {
                Components.serverWakingUpView(vm.isServerWakingUp)
            } else {
                VStack(spacing: 100) {
                    VStack(spacing: 15) {
                        Components.logoImage(65)

                        Text("Добро пожаловать")
                            .fontDesign(.monospaced)
                            .bold()
                    }

                    VStack(spacing: 15) {
                        SignInCreateAccountButtonView(type: .signIn,
                                                      isSignedOut: true) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                vm.showSignIn.toggle()
                            }
                        }

                        SignInCreateAccountButtonView(type: .createAccount,
                                                      isSignedOut: true) {
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
                .alert(vm.alertMessage, isPresented: $vm.showAlert) {
                    Button("ОК", role: .cancel) {}
                }
                .onDisappear {
                    vm.closeSignInCreateViews()
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .animation(.easeInOut(duration: 0.25), value: vm.isServerWakingUp)
    }
}

extension SignedOutView {
    @ViewBuilder
    private func overlayView() -> some View {
        if vm.showSignIn {
            SignInCreateAccountView(vm: vm,
                                    type: .signIn,
                                    showSignInCreate: $vm.showSignIn) {
                withAnimation(.spring) {
                    vm.showSignIn = false
                    vm.showCreateAccount = true
                }
            }
        } else if vm.showCreateAccount {
            SignInCreateAccountView(vm: vm,
                                    type: .createAccount,
                                    showSignInCreate: $vm.showCreateAccount) {
                withAnimation(.spring) {
                    vm.showCreateAccount = false
                    vm.showSignIn = true
                }
            }
        }
    }
}

#Preview {
    SignedOutView(vm: ProfileViewModel(authService: AuthService(),
                                       contentService: ContentService()))
}
