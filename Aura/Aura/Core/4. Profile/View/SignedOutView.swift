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
            
            VStack(spacing: 100) {
                VStack(spacing: 15) {
                    Components.logoImage(65)
                    
                    Text("Добро пожаловать")
                        .fontDesign(.monospaced)
                        .bold()
                }
                
                VStack(spacing: 15) {
                    SignedOutButtonView(type: .signIn) {
                        withAnimation(.spring) {
                            showSignIn.toggle()
                        }
                    }
                    
                    SignedOutButtonView(type: .createAccout) {
                        withAnimation(.spring) {
                            showCreateAccount.toggle()
                        }
                    }
                }
                .padding(.bottom, 165)
            }
            .padding(.horizontal)
            .overlay {
                if showSignIn {
                    SignInCreateAccountView(vm: vm, type: .signIn,
                                            showSignInCreate: $showSignIn) {
                        withAnimation(.spring) {
                            showSignIn = false
                            showCreateAccount = true
                        }
                    }
                } else if showCreateAccount {
                    SignInCreateAccountView(vm: vm, type: .createAccount,
                                            showSignInCreate: $showCreateAccount) {
                        withAnimation(.spring) {
                            showCreateAccount = false
                            showSignIn = true
                        }
                    }
                }
            }
        }
    }
}

#Preview {
//    SignedOutView(vm: ProfileViewModel(authService: MockAuthService()))
}
