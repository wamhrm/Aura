//
//  LoadingView.swift
//  Aura
//
//  Created by wamhrm on 13/11/2026.
//

import SwiftUI

enum LoadState: Equatable {
    case loading, loaded
    case failed(String)
}

struct LoadingView: View {
    let title: LocalizedStringResource
    var isPresented = true

    @State private var isRotating = false
    @State private var phraseIndex = 0
    @State private var textOpacity = 1.0

    private var phrases: [LocalizedStringResource] {
        [title, "Ещё немного", "Почти готово"]
    }

    private var phrase: LocalizedStringResource {
        phrases[phraseIndex % phrases.count]
    }

    var body: some View {
        ZStack {
            BackgroundView()

            VStack(spacing: 30) {
                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.fieldBorder, lineWidth: 4)

                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(.tint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(isRotating ? 360 : 0))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false),
                                   value: isRotating)

                    Image(systemName: "sparkles")
                        .font(.system(size: 17))
                        .fontWeight(.semibold)
                        .foregroundStyle(.tint)
                }
                .frame(width: 35, height: 35)

                Text(phrase)
                    .font(Adaptive.size(.callout, .default, .default))
                    .bold()
                    .multilineTextAlignment(.center)
                    .opacity(textOpacity)

                Spacer()
            }
            .padding(.horizontal)
            .onAppear {
                isRotating = true
            }
            .task(id: "\(isPresented)-\(title.key)") {
                phraseIndex = 0
                textOpacity = 1
                guard isPresented else { return }

                while !Task.isCancelled {
                    await showNextPhrase()
                }
            }
        }
    }

    private func showNextPhrase() async {
        try? await Task.sleep(for: .seconds(4))
        guard !Task.isCancelled else { return }

        withAnimation(.easeInOut(duration: 0.35)) {
            textOpacity = 0
        }

        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled else { return }

        phraseIndex = (phraseIndex + 1) % phrases.count
        
        withAnimation(.easeInOut(duration: 0.35)) {
            textOpacity = 1
        }
    }
}


#Preview("Loading") {
    LoadingView(title: "Сохраняем профиль и настройки")
}
