//
//  AIConsentView.swift
//  Aura
//
//  Created by wamhrm on 23.10.2026.
//

import SwiftUI

struct AIConsentView: View {
    @ObservedObject var vm: AIConsentViewModel

    var body: some View {
        VStack(spacing: 20) {
            AIConsentContentView()

            VStack(spacing: 5) {
                ClassicButton(title: vm.allowButtonTitle) {
                    vm.accept()
                }

                Button {
                    vm.decline()
                } label: {
                    Text("Не сейчас")
                        .font(.system(size: Adaptive.size(14, 15)))
                        .foregroundStyle(.deepGray)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .disabled(vm.isLoading)
        }
        .padding(.horizontal)
        .interactiveDismissDisabled(vm.isLoading)
        .alert(vm.alertMessage, isPresented: $vm.showAlert) {
            Button("OK", role: .cancel) {}
        }
    }
}

struct AIConsentContentView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                headerView()

                Text("Инсайт и совет дня, тесты личности и совместимости составляет сервис искусственного интеллекта OpenAI (США). Для этого Aura передаёт ему:")

                VStack(alignment: .leading, spacing: 8) {
                    bulletText("дату и время рождения, пол и ответы анкеты;")
                    bulletText("для теста совместимости — дату рождения или возраст, время рождения и пол партнёра.")
                }

                Text("Имена и адрес почты не передаются. Гороскоп работает и без этого разрешения.")

                if let url = Constants.privacyPolicyURL {
                    Link("Политика конфиденциальности", destination: url)
                        .fontWeight(.semibold)
                }
            }
            .font(Adaptive.size(.system(size: 14), .callout))
            .padding(.top, 30)
        }
        .scrollIndicators(.hidden)
    }
}

extension AIConsentContentView {
    private func headerView() -> some View {
        VStack(spacing: 15) {
            Image(systemName: "sparkles")
                .font(Adaptive.size(.title2, .title3))
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(15)
                .background(LinearGradient(colors: [.purple, .softPurple],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing))
                .clipShape(Circle())

            Text("Анализ с помощью AI")
                .font(Adaptive.size(.default, .title3))
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 10)
    }

    private func bulletText(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("•")

            Text(text)
        }
    }
}

#Preview {
    AIConsentView(vm: AIConsentViewModel(authService: AuthService()))
}
