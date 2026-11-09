//
//  LoadingStepView.swift
//  Aura
//
//  Created by wamhrm on 27.10.2026.
//

import SwiftUI

struct LoadingStepView: View {
    @ObservedObject var vm: OnboardingViewModel
    @State private var isRotating = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            loaderView()

            Text(vm.loadingTitle)
                .font(Adaptive.size(.title3, .title2))
                .bold()
                .multilineTextAlignment(.center)

            if vm.hasLoadingFailed {
                VStack(spacing: 15) {
                    Text(vm.alertMessage)
                        .font(Adaptive.size(.footnote, .callout))
                        .foregroundStyle(.deepGray)
                        .multilineTextAlignment(.center)

                    ClassicButton(title: "Повторить") {
                        vm.retryLoading()
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .onAppear { isRotating = true }
    }
}

extension LoadingStepView {
    private func loaderView() -> some View {
        ZStack {
            Circle()
                .stroke(Color.fieldBorder, lineWidth: 10)

            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(.tint, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(isRotating ? 360 : 0))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isRotating)
                .opacity(vm.hasLoadingFailed ? 0 : 1)

            Image(systemName: vm.loadingIcon)
                .font(.system(size: 40))
                .fontWeight(.semibold)
                .foregroundStyle(.tint)
        }
        .frame(width: 130, height: 130)
    }
}

#Preview {
    LoadingStepView(vm: OnboardingViewModel(authService: AuthService.preview))
}
