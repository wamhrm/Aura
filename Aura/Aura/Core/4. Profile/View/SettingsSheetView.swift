//
//  SettingsSheetView.swift
//  Aura
//
//  Created by wamhrm on 07.05.2026.
//

import SwiftUI

struct SettingsSheetView: View {
    @ObservedObject var vm: ProfileViewModel
    
    @AppStorage(Constants.selectedThemeKey, store: Constants.userDefaults) private var selectedTheme = AppTheme.light
    @AppStorage(Constants.accentColorKey, store: Constants.userDefaults) private var accentColor = AccentColorOption.blue.rawValue
    @AppStorage(Constants.appLanguage, store: Constants.userDefaults) private var appLanguage = AppLanguage.system
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundView()
                
                VStack(alignment: .leading, spacing: 30) {
                    VStack(alignment: .leading, spacing: 15) {
                        headerText("Оформление")

                        HStack(spacing: 15) {
                            themeButton(.light)
                            themeButton(.dark)
                        }
                    }

                    VStack(alignment: .leading, spacing: 15) {
                        headerText("Акцентный цвет")

                        HStack {
                            ForEach(AccentColorOption.allCases) { option in
                                let isSelected = accentColor == option.rawValue
                                accentColorView(color: option.color,
                                                isSelected: isSelected) {
                                    accentColor = option.rawValue
                                }
                                .accessibilityLabel(option.title)
                                .accessibilityAddTraits(isSelected ? .isSelected : [])
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 15) {
                        headerText("Язык")
                        languageMenu()
                    }

                    VStack(spacing: 15) {
                        customButton(.updateInfo) {
                            vm.editProfileAfterSettings()
                        }

                        customButton(.signOut) {
                            vm.requestSignOut()
                        }

                        customButton(.deleteAccount, isLoading: vm.isDeletingAccount) {
                            vm.requestAccountDeletion()
                        }
                        .alert("Удалить аккаунт?", isPresented: $vm.showDeleteAccountAlert) {
                            deleteAccountAlertView()
                        } message: {
                            Text("Профиль, история тестов и все результаты будут удалены без возможности восстановления.")
                        }
                    }
                    .disabled(vm.isDeletingAccount)

                    legalLinksView()
                }
                .padding(.horizontal)
                .localizedNavigationTitle("Настройки")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarItem()
                }
                .alert("Выйти из аккаунта?",
                       isPresented: $vm.showSignOutAlert) {
                    alertView()
                }
            }
        }
        .interactiveDismissDisabled(vm.isDeletingAccount)
        .alert(vm.alertMessage, isPresented: $vm.showAlert) {
            Button("ОК", role: .cancel) {}
        }
        .alert("Не удалось удалить аккаунт",
               isPresented: $vm.showDeleteAccountError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.alertMessage)
        }
    }
}

extension SettingsSheetView {
    @ToolbarContentBuilder
    private func toolbarItem() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(role: .cancel) {
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .disabled(vm.isDeletingAccount)
        }
    }
    
    @ViewBuilder
    private func alertView() -> some View {
        Button("Отмена", role: .cancel) {}
        Button("Выйти", role: .destructive) {
            vm.signOut()
        }
    }

    @ViewBuilder
    private func deleteAccountAlertView() -> some View {
        Button("Отмена", role: .cancel) {}
        Button("Удалить", role: .destructive) {
            vm.deleteAccount()
        }
    }

    private func legalLinksView() -> some View {
        HStack(spacing: 20) {
            if let url = Constants.privacyPolicyURL {
                Link("Политика конфиденциальности", destination: url)
            }

            if let url = Constants.termsOfUseURL {
                Link("Условия использования", destination: url)
            }
        }
        .font(Adaptive.size(.caption, .footnote, .footnote))
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
    }
    
    private func languageMenu() -> some View {
        Menu {
            Picker("Язык", selection: $appLanguage) {
                ForEach(AppLanguage.allCases) { language in
                    languageTitle(language).tag(language)
                }
            }
        } label: {
            HStack(spacing: 10) {
                languageTitle(appLanguage)

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
            }
            .padding(.vertical, 13)
            .padding(.horizontal, 14)
            .font(Adaptive.size(.footnote, .system(size: 14), .system(size: 15)))
            .frame(maxWidth: .infinity)
            .foregroundStyle(.primary)
            .clipShape(.rect(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func languageTitle(_ language: AppLanguage) -> Text {
        switch language {
            case .system: Text("Как в iPhone")
            case .russian: Text(verbatim: "Русский")
            case .english: Text(verbatim: "English")
        }
    }

    private func headerText(_ title: LocalizedStringResource) -> some View {
        Text(title)
            .font(Adaptive.size(.system(size: 15), .callout, .default))
            .foregroundStyle(.secondary)
    }

    private func customButton(_ type: ButtonTypes,
                              isLoading: Bool = false,
                              _ completion: @escaping () -> Void) -> some View {
        Button(action: completion) {
            Text(type.title)
                .font(Adaptive.size(.footnote, .system(size: 14), .system(size: 15)))
                .bold()
                .foregroundStyle(type.foregroundColor)
                .opacity(isLoading ? 0 : 1)
                .overlay {
                    if isLoading {
                        ProgressView()
                            .tint(type.foregroundColor)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(type.backgroundColor)
                .overlay {
                    RoundedRectangle(cornerRadius: 10).stroke(type.stroke, lineWidth: 2)
                }
                .clipShape(.rect(cornerRadius: 10))
        }
    }
    
    private func themeButton(_ theme: AppTheme) -> some View {
        Button {
            selectedTheme = theme
        } label: {
            let isSelected = selectedTheme == theme

            HStack(spacing: 10) {
                Image(systemName: theme.icon)
                
                Text(theme.title)
            }
            .padding(.vertical, 13)
            .font(Adaptive.size(.footnote, .system(size: 14), .system(size: 15)))
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .foregroundStyle(isSelected ? .blue : .primary)
            .clipShape(.rect(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.25), lineWidth: 1))
        }
    }
    
    private func accentColorView(color: Color,
                                 isSelected: Bool,
                                 onTapHandler: @escaping () -> Void) -> some View {
        Button(action: onTapHandler) {
            Circle()
                .fill(color)
                .frame(width: Adaptive.size(30, 30, 32), height: Adaptive.size(30, 30, 32))
                .overlay(Circle().stroke(Color.white, lineWidth: 1))
                .overlay(Circle().stroke(isSelected ? Color(.systemGray2) : Color.clear, lineWidth: 4))
                .shadow(color: .black.opacity(0.1), radius: 2)
        }
    }
}

fileprivate enum ButtonTypes {
    case updateInfo, signOut, deleteAccount

    var title: LocalizedStringResource {
        switch self {
            case .updateInfo: "Обновить информацию о себе"
            case .signOut: "Выйти"
            case .deleteAccount: "Удалить аккаунт"
        }
    }

    var backgroundColor: Color {
        switch self {
            case .updateInfo:
                .blue.opacity(0.155)
            case .signOut:
                .red.opacity(0.155)
            case .deleteAccount:
                .clear
        }
    }

    var foregroundColor: Color {
        switch self {
            case .updateInfo:
                .blue
            case .signOut, .deleteAccount:
                .red
        }
    }

    var stroke: Color {
        switch self {
            case .updateInfo:
                .blue.opacity(0.25)
            case .signOut, .deleteAccount:
                .red.opacity(0.25)
        }
    }
}

private extension AppTheme {
    var title: LocalizedStringResource {
        switch self {
            case .light: "Светлая"
            case .dark: "Темная"
        }
    }
    
    var icon: String {
        switch self {
            case .light: "sun.max.fill"
            case .dark: "moon.fill"
        }
    }
}

#Preview {
    let services = PreviewServices()
    SettingsSheetView(vm: ProfileViewModel(authService: services.authService,
                                           contentService: services.contentService))
}
