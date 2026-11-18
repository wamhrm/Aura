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
                        headerText(AppLanguage.text("Оформление"))

                        HStack(spacing: 15) {
                            themeButton(.light)
                            themeButton(.dark)
                        }
                    }

                    VStack(alignment: .leading, spacing: 15) {
                        headerText(AppLanguage.text("Акцентный цвет"))

                        HStack {
                            ForEach(AccentColorOption.allCases) { option in
                                accentColorView(color: option.color,
                                                isSelected: accentColor == option.rawValue) {
                                    accentColor = option.rawValue
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 15) {
                        headerText(AppLanguage.text("Язык"))
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
                        .alert(AppLanguage.text("Удалить аккаунт?"), isPresented: Binding {
                            vm.showDeleteAccountAlert
                        } set: { newValue in
                            if vm.showDeleteAccountAlert != newValue { vm.showDeleteAccountAlert = newValue }
                        }) {
                            deleteAccountAlertView()
                        } message: {
                            Text(AppLanguage.text("Профиль, история тестов и все результаты будут удалены без возможности восстановления."))
                        }
                    }
                    .disabled(vm.isDeletingAccount)

                    legalLinksView()
                }
                .padding(.horizontal)
                .navigationTitle(AppLanguage.text("Настройки"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarItem()
                }
                .alert(AppLanguage.text("Выйти из аккаунта?"), isPresented: Binding {
                    vm.showSignOutAlert
                } set: { newValue in
                    if vm.showSignOutAlert != newValue { vm.showSignOutAlert = newValue }
                }) {
                    alertView()
                }
            }
        }
        .interactiveDismissDisabled(vm.isDeletingAccount)
        .alert(vm.alertMessage, isPresented: vm.alertBinding) {
            Button(AppLanguage.text("ОК"), role: .cancel) {}
        }
        .alert(AppLanguage.text("Не удалось удалить аккаунт"), isPresented: Binding {
            vm.showDeleteAccountError
        } set: { newValue in
            if vm.showDeleteAccountError != newValue { vm.showDeleteAccountError = newValue }
        }) {
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
        Button(AppLanguage.text("Отмена"), role: .cancel) {}
        Button(AppLanguage.text("Выйти"), role: .destructive) {
            vm.signOut()
        }
    }

    @ViewBuilder
    private func deleteAccountAlertView() -> some View {
        Button(AppLanguage.text("Отмена"), role: .cancel) {}
        Button(AppLanguage.text("Удалить"), role: .destructive) {
            vm.deleteAccount()
        }
    }

    private func legalLinksView() -> some View {
        HStack(spacing: 20) {
            if let url = Constants.privacyPolicyURL {
                Link(AppLanguage.text("Политика конфиденциальности"), destination: url)
            }

            if let url = Constants.termsOfUseURL {
                Link(AppLanguage.text("Условия использования"), destination: url)
            }
        }
        .font(Adaptive.size(.caption, .footnote, .footnote))
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
    }
    
    private func languageMenu() -> some View {
        Menu {
            Picker(AppLanguage.text("Язык"), selection: $appLanguage) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.title).tag(language)
                }
            }
        } label: {
            HStack(spacing: 10) {
                Text(appLanguage.title)

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

    private func headerText(_ title: String) -> some View {
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
        let isSelected = selectedTheme == theme

        return Button {
            selectedTheme = theme
        } label: {
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

    var title: String {
        switch self {
            case .updateInfo: AppLanguage.text("Обновить информацию о себе")
            case .signOut: AppLanguage.text("Выйти")
            case .deleteAccount: AppLanguage.text("Удалить аккаунт")
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
    var title: String {
        switch self {
            case .light: AppLanguage.text("Светлая")
            case .dark: AppLanguage.text("Темная")
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
