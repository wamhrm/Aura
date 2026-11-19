//
//  OnboardingComponents.swift
//  Aura
//
//  Created by wamhrm on 27.10.2026.
//

import SwiftUI

struct OnboardingHeader: View {
    let title: LocalizedStringResource
    let subtitle: LocalizedStringResource

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(Adaptive.size(.title3, .system(size: 21), .title2))
                .bold()

            Text(subtitle)
                .font(Adaptive.size(.caption, .system(size: 14), .callout))
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
                    SecureField(type.title, text: $text)
                } else {
                    TextField(type.title, text: $text)
                        .keyboardType(type.keyboardType)
                }
            }
            .textContentType(type.contentType)
            .textInputAutocapitalization(type == .name ? .words : .never)
            .autocorrectionDisabled()
            .onChange(of: text) { _, newValue in
                guard type == .name else { return }
                let capitalized = newValue.capitalized
                if capitalized != newValue {
                    text = capitalized
                }
            }

            if type.isSecure {
                Button {
                    isTextVisible.toggle()
                } label: {
                    Image(systemName: isTextVisible ? "eye.slash" : "eye")
                        .foregroundStyle(.deepGray)
                }
                .accessibilityLabel(isTextVisible ? "Скрыть пароль" : "Показать пароль")
            }
        }
        .font(Adaptive.size(.callout, .body, .body))
        .padding(.horizontal)
        .frame(height: Adaptive.size(48, 50, 52))
        .background(Color.cardBackground)
        .clipShape(.rect(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.fieldBorder, lineWidth: 1.5))
    }
}

struct OnboardingTextButton: View {
    let title: LocalizedStringResource
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Adaptive.size(.footnote, .system(size: 14), .callout))
                .fontWeight(.semibold)
                .foregroundStyle(.tint)
        }
    }
}

struct OnboardingLegalText: View {
    @Environment(\.locale) private var locale

    var body: some View {
        let terms = Constants.termsOfUseURL?.absoluteString ?? ""
        let privacy = Constants.privacyPolicyURL?.absoluteString ?? ""
        let message = String(localized: LocalizedStringResource(
            "Продолжая, вы принимаете [Условия использования](\(terms)) и [Политику конфиденциальности](\(privacy))",
            locale: locale))
        let links = try? AttributedString(markdown: message, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))

        Text(links ?? AttributedString(message))
            .font(Adaptive.size(.caption2, .caption, .caption))
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

enum OnboardingTextFieldTypes {
    case name, email, password, newPassword, code

    fileprivate var title: LocalizedStringResource {
        switch self {
            case .name: "Имя"
            case .email: "Электронная почта"
            case .password: "Пароль"
            case .newPassword: "Новый пароль"
            case .code: "Код из 6 цифр"
        }
    }

    fileprivate var isSecure: Bool {
        switch self {
            case .password, .newPassword: true
            case .name, .email, .code: false
        }
    }

    fileprivate var keyboardType: UIKeyboardType {
        switch self {
            case .email: .emailAddress
            case .code: .numberPad
            case .name, .password, .newPassword: .default
        }
    }

    fileprivate var contentType: UITextContentType? {
        switch self {
            case .name: .givenName
            case .email: .emailAddress
            case .password: .password
            case .code: .oneTimeCode
            case .newPassword: nil
        }
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
