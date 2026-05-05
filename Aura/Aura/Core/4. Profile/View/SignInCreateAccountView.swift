//
//  SignInCreateAccountView.swift
//  Aura
//
//  Created by ddorsat on 07.05.2026.
//

import SwiftUI

struct SignInCreateAccountView: View {
    @ObservedObject var vm: ProfileViewModel
    let type: SignInCreateAccountType
    @Binding var showSignInCreate: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            HStack {
                Text(type == .signIn ? "Войти" : "Создать аккаунт")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    withAnimation(.spring) {
                        showSignInCreate.toggle()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.deepBlue)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
            }
            
            if type == .signIn {
                VStack(spacing: 10) {
                    SignInCreateAccountTextFieldView(type: .email, field: $vm.email)
                    SignInCreateAccountTextFieldView(type: .password, field: $vm.password)
                    SignInCreateAccountButtonView(type: .signIn, signedOut: false) {
                        
                    }
                    .padding(.top, 5)
                }
            } else {
                VStack(spacing: 10) {
                    SignInCreateAccountTextFieldView(type: .name, field: $vm.name)
                    SignInCreateAccountTextFieldView(type: .email, field: $vm.email)
                    SignInCreateAccountTextFieldView(type: .password, field: $vm.password)
                    SignInCreateAccountButtonView(type: .createAccount, signedOut: false) {
                        
                    }
                    .padding(.top, 5)
                }
            }
            
            HStack(spacing: 15) {
                Rectangle()
                    .frame(height: 0.5)
                
                Text("или")
                
                Rectangle()
                    .frame(height: 0.5)
            }
            .foregroundStyle(.gray)
            
            VStack(spacing: 10) {
                SignInCreateAccountButtonView(type: .google, signedOut: false) {
                    
                }
                
                SignInCreateAccountButtonView(type: .apple, signedOut: false) {
                    
                }
            }
            
            if type == .signIn {
                SignInAlreadyHaveAccountView(type: .signIn) {
                    
                }
            } else {
                SignInAlreadyHaveAccountView(type: .alreadyHaveAccount) {
                    
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: type == .signIn ? 520 : 610)
        .padding(25)
        .background(RoundedRectangle(cornerRadius: 20) .fill(.white))
        .padding(.horizontal)
    }
}

enum SignInCreateAccountType: String {
    case signIn = "Войти"
    case createAccount = "Создать аккаунт"
}

#Preview {
    SignInCreateAccountView(vm: ProfileViewModel(), type: .createAccount, showSignInCreate: .constant(false))
}
