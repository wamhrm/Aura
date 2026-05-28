//
//  SignedOutView.swift
//  Aura
//
//  Created by ddorsat on 07.05.2026.
//

import SwiftUI

struct SignedOutView: View {
    @ObservedObject var vm: ProfileViewModel
    @State var showSignIn = false
    @State var showCreateAccount = false
    
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
                        SignInCreateAccountButtonView(type: .signIn, isSignedOut: true) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showSignIn.toggle()
                            }
                        }
                        
                        SignInCreateAccountButtonView(type: .createAccount, isSignedOut: true) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showCreateAccount.toggle()
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
    }
}

extension SignedOutView {
    @ViewBuilder
    private func overlayView() -> some View {
        if showSignIn {
            SignInCreateAccountView(vm: vm, type: .signIn,
                                    showSignInCreate: $showSignIn) {
                withAnimation(.spring) {
                    showSignIn = false
                    showCreateAccount = true
                    vm.clearTextFields()
                }
            }
        } else if showCreateAccount {
            SignInCreateAccountView(vm: vm, type: .createAccount,
                                    showSignInCreate: $showCreateAccount) {
                withAnimation(.spring) {
                    showCreateAccount = false
                    showSignIn = true
                    vm.clearTextFields()
                }
            }
        }
    }
}

#Preview {
    SignedOutView(vm: ProfileViewModel(authService: AuthService(),
                                       contentService: ContentService()))
}
