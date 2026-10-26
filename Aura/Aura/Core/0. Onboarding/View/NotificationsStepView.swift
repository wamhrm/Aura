//
//  NotificationsStepView.swift
//  Aura
//
//  Created by ddorsat on 27.10.2026.
//

import SwiftUI

struct NotificationsStepView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 25) {
            Spacer()

            OnboardingIcon(icon: "bell.badge", size: Adaptive.size(110, 130))

            VStack(spacing: 10) {
                Text("Не пропускайте главное")
                    .font(Adaptive.size(.title2, .title))
                    .bold()

                Text("Пришлём напоминание, когда будут готовы новый гороскоп и инсайт дня")
                    .font(Adaptive.size(.callout, .body))
                    .foregroundStyle(.deepGray)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 25)

            Spacer()

            VStack(spacing: 15) {
                // TODO: request notification permission
                ClassicButton(title: "Включить уведомления") {
                    vm.continueFromNotifications()
                }

                OnboardingTextButton(title: "Позже") {
                    vm.continueFromNotifications()
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
    }
}
