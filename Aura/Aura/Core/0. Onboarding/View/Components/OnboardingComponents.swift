//
//  OnboardingComponents.swift
//  Aura
//
//  Created by wamhrm on 27.10.2026.
//

import SwiftUI

struct OnboardingHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(Adaptive.size(.title3, .title2))
                .bold()

            Text(subtitle)
                .font(Adaptive.size(.caption, .callout))
                .foregroundStyle(.deepGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct OnboardingTextField: View {
    @State private var isTextVisible = false
    @Binding var text: String
    let type: OnboardingTextFieldTypes

    var body: some View {
        HStack {
            Group {
                if type.isSecure && !isTextVisible {
                    SecureField(type.rawValue, text: $text)
                } else {
                    TextField(type.rawValue, text: $text)
                        .keyboardType(type.keyboardType)
                }
            }
            .textContentType(type.contentType)
            .textInputAutocapitalization(type == .name ? .words : .never)
            .autocorrectionDisabled()

            if type.isSecure {
                Button {
                    isTextVisible.toggle()
                } label: {
                    Image(systemName: isTextVisible ? "eye.slash" : "eye")
                        .foregroundStyle(.deepGray)
                }
            }
        }
        .font(Adaptive.size(.callout, .body))
        .padding(.horizontal)
        .frame(height: Adaptive.size(48, 52))
        .background(Color.cardBackground)
        .clipShape(.rect(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.fieldBorder, lineWidth: 1.5))
    }
}

struct OnboardingTextButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Adaptive.size(.footnote, .callout))
                .fontWeight(.semibold)
                .foregroundStyle(.tint)
        }
    }
}

struct OnboardingLegalText: View {
    private var legalText: LocalizedStringKey {
        let terms = Constants.termsOfUseURL?.absoluteString ?? ""
        let privacy = Constants.privacyPolicyURL?.absoluteString ?? ""
        let text = "Продолжая, вы принимаете [Условия использования](\(terms)) и [Политику конфиденциальности](\(privacy))"
        return LocalizedStringKey(text)
    }

    var body: some View {
        Text(legalText)
            .font(Adaptive.size(.caption2, .caption))
            .foregroundStyle(.deepGray)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}

struct OnboardingIcon: View {
    let icon: String
    let size: CGFloat

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.4))
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(LinearGradient(colors: [.purple, .softPurple],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing))
            .clipShape(.circle)
    }
}

enum OnboardingTextFieldTypes: String {
    case name = "Имя"
    case email = "Электронная почта"
    case password = "Пароль"
    case newPassword = "Новый пароль"
    case code = "Код из 6 цифр"

    var isSecure: Bool {
        switch self {
            case .password, .newPassword: true
            case .name, .email, .code: false
        }
    }

    var keyboardType: UIKeyboardType {
        switch self {
            case .email: .emailAddress
            case .code: .numberPad
            case .name, .password, .newPassword: .default
        }
    }

    var contentType: UITextContentType? {
        switch self {
            case .name: .givenName
            case .email: .emailAddress
            case .password: .password
            case .code: .oneTimeCode
            case .newPassword: nil
        }
    }
}

struct LoadingView: View {
    let title: String
    @State private var isRotating = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.fieldBorder, lineWidth: 5)

                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(.tint, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(isRotating ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isRotating)

                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .fontWeight(.semibold)
                    .foregroundStyle(.tint)
            }
            .frame(width: 40, height: 40)

            Text(title)
                .font(Adaptive.size(.title3, .callout))
                .bold()
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.horizontal)
        .onAppear {
            isRotating = true
        }
    }
}

#Preview("Loading") {
    ZStack {
        BackgroundView()
        LoadingView(title: "Сохраняем профиль и настройки")
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            OnboardingHeader(title: "Придумайте пароль", subtitle: "Не меньше 8 символов")

            OnboardingTextField(text: .constant(""), type: .password)

            OnboardingTextButton(title: "Забыли пароль?") {

            }

            OnboardingLegalText()

            OnboardingIcon(icon: "bell.badge", size: 80)
        }
    }
}
