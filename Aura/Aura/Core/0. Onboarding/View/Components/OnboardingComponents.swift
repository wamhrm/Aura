//
//  OnboardingComponents.swift
//  Aura
//
//  Created by wamhrm on 27.10.2026.
//

import AuthenticationServices
import SwiftUI

struct OnboardingTopBar: View {
    let progress: Double?
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

    var body: some View {
        HStack(spacing: 15) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(Adaptive.size(.title3, .title2))
                    .fontWeight(.semibold)
                    .foregroundStyle(.deepGray)
            }

            if let progress {
                GeometryReader { bar in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.fieldBorder)

                        Capsule()
                            .fill(AccentColorOption.color(accentColor))
                            .frame(width: bar.size.width * progress)
                    }
                }
                .frame(height: 10)
            } else {
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.3), value: progress)
    }
}

struct OnboardingHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Adaptive.size(.title2, .title))
                .bold()

            Text(subtitle)
                .font(Adaptive.size(.footnote, .callout))
                .foregroundStyle(.deepGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct OnboardingTextField: View {
    let type: OnboardingTextFieldTypes
    @Binding var text: String
    @State private var isTextVisible = false

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
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.fieldBorder, lineWidth: 1.5))
    }
}

struct OnboardingTextButton: View {
    let title: String
    let action: () -> Void
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Adaptive.size(.footnote, .callout))
                .fontWeight(.semibold)
                .foregroundStyle(AccentColorOption.color(accentColor))
        }
    }
}

struct OnboardingDivider: View {
    var body: some View {
        HStack(spacing: 15) {
            Rectangle()
                .frame(height: 0.5)

            Text("или")
                .font(Adaptive.size(.callout, .system(size: 15)))

            Rectangle()
                .frame(height: 0.5)
        }
        .foregroundStyle(.gray)
    }
}

struct OnboardingAppleButton: View {
    @ObservedObject var vm: OnboardingViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        SignInWithAppleButton(.continue) { request in
            vm.prepareAppleSignIn(request)
        } onCompletion: { result in
            vm.completeAppleSignIn(result)
        }
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct OnboardingLegalText: View {
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue
    
    private var legalText: LocalizedStringKey {
        let terms = Constants.termsOfUseURL?.absoluteString ?? ""
        let privacy = Constants.privacyPolicyURL?.absoluteString ?? ""
        return "Продолжая, вы принимаете [Условия использования](\(terms)) и [Политику конфиденциальности](\(privacy))"
    }

    var body: some View {
        Text(legalText)
            .font(Adaptive.size(.caption2, .caption))
            .foregroundStyle(.deepGray)
            .multilineTextAlignment(.center)
            .tint(AccentColorOption.color(accentColor))
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
            .clipShape(Circle())
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

#Preview {
    VStack(spacing: 20) {
        OnboardingTopBar(progress: 0.3)

        OnboardingHeader(title: "Придумайте пароль", subtitle: "Не меньше 6 символов")

        OnboardingTextField(type: .password, text: .constant(""))

        OnboardingTextButton(title: "Забыли пароль?") {

        }

        OnboardingDivider()

        OnboardingAppleButton(vm: OnboardingViewModel(authService: AuthService(),
                                                      contentService: ContentService()) {})

        OnboardingLegalText()

        OnboardingIcon(icon: "bell.badge", size: 80)
    }
    .padding(.horizontal)
}
