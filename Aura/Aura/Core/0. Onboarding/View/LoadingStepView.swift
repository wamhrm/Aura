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
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            loaderView()

            Text(vm.hasLoadingFailed ? "Не удалось подготовить профиль" : "Составляем ваш профиль")
                .font(Adaptive.size(.title3, .title2))
                .bold()
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 15) {
                ForEach(vm.loadingStages, id: \.self) { stage in
                    stageView(stage)
                }
            }

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
                .stroke(AccentColorOption.color(accentColor), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(isRotating ? 360 : 0))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isRotating)
                .opacity(vm.hasLoadingFailed ? 0 : 1)

            Image(systemName: vm.hasLoadingFailed ? "exclamationmark" : "sparkles")
                .font(.system(size: 40))
                .fontWeight(.semibold)
                .foregroundStyle(AccentColorOption.color(accentColor))
        }
        .frame(width: 130, height: 130)
    }

    private func stageView(_ stage: OnboardingLoadingStage) -> some View {
        HStack(spacing: 12) {
            if vm.completedLoadingStages.contains(stage) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(AccentColorOption.color(accentColor))
            } else {
                ProgressView()
                    .frame(width: 22, height: 22)
            }

            Text(stage.title)
                .font(Adaptive.size(.callout, .body))
                .fontWeight(.medium)
        }
    }
}
