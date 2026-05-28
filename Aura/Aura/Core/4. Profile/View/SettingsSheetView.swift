//
//  SettingsSheetView.swift
//  Aura
//
//  Created by ddorsat on 07.05.2026.
//

import SwiftUI

struct SettingsSheetView: View {
    @ObservedObject var vm: ProfileViewModel
    let isSignedOut: Bool
    @Environment(\.dismiss) private var dismiss
    private let onUpdateInfo: () -> Void
    private let onSignOut: () -> Void
    
    @AppStorage(Constants.selectedThemeKey) private var selectedTheme = AppTheme.light
    @AppStorage(Constants.accentColorKey) private var accentColor = AccentColorOption.blue.rawValue

    init(vm: ProfileViewModel,
         isSignedOut: Bool,
         onUpdateInfo: @escaping () -> Void,
         onSignOut: @escaping () -> Void) {
        self.vm = vm
        self.isSignedOut = isSignedOut
        self.onUpdateInfo = onUpdateInfo
        self.onSignOut = onSignOut
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 30) {
                VStack(alignment: .leading, spacing: 15) {
                    headerText("Оформление")

                    HStack(spacing: 15) {
                        themeButtonsView(type: .bright,
                                         isSelected: selectedTheme == .light) {
                            selectedTheme = .light
                        }

                        themeButtonsView(type: .dark,
                                         isSelected: selectedTheme == .dark) {
                            selectedTheme = .dark
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 15) {
                    headerText("Акцентный цвет")

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

                if !isSignedOut {
                    VStack(spacing: 15) {
                        customButton(.updateInfo) {
                            onUpdateInfo()
                            dismiss()
                        }

                        customButton(.signOut) {
                            vm.showAlert.toggle()
                        }
                    }
                }
            }
            .padding(.horizontal)
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarItem()
            }
            .alert("Выйти из аккаунта?", isPresented: $vm.showAlert) {
                alertView()
            }
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
        }
    }
    
    @ViewBuilder
    private func alertView() -> some View {
        Button("Отмена", role: .cancel) {}
        Button("Выйти", role: .destructive) {
            onSignOut()
            dismiss()
        }
        .disabled(vm.isLoading)
    }
    
    private func headerText(_ title: String) -> some View {
        Text(title)
            .font(Components.displaySize(.system(size: 15), .default))
            .foregroundStyle(.secondary)
    }

    private func customButton(_ type: ButtonTypes,
                              _ completion: @escaping () -> Void) -> some View {
        Button {
            completion()
        } label: {
            VStack(alignment: .center) {
                Text(type.rawValue)
                    .font(Components.displaySize(.footnote, .system(size: 15)))
                    .bold()
                    .foregroundStyle(type.foregroundColor)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(type.backgroundColor)
            .overlay {
                RoundedRectangle(cornerRadius: 10) .stroke(type.stroke, lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    
    private func themeButtonsView(type: ThemeButtonTypes,
                                  isSelected: Bool,
                                  onTapHandler: @escaping () -> Void) -> some View {
        Button(action: onTapHandler) {
            HStack(spacing: 10) {
                Image(systemName: type.icon)
                
                Text(type.rawValue)
            }
            .padding(.vertical, 13)
            .font(Components.displaySize(.footnote, .system(size: 15)))
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .foregroundStyle(isSelected ? .blue : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
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
                .frame(width: Components.displaySize(30, 32), height: Components.displaySize(30, 32))
                .overlay(Circle() .stroke(Color.white, lineWidth: 1))
                .overlay(Circle() .stroke(isSelected ? Color(.systemGray2) : Color.clear, lineWidth: 4))
                .shadow(color: .black.opacity(0.1), radius: 2)
        }
    }
}

fileprivate enum ButtonTypes: String {
    case updateInfo = "Обновить информацию о себе"
    case signOut = "Выйти"

    var backgroundColor: Color {
        switch self {
            case .updateInfo:
                .blue.opacity(0.155)
            case .signOut:
                .red.opacity(0.155)
        }
    }

    var foregroundColor: Color {
        switch self {
            case .updateInfo:
                .blue
            case .signOut:
                .red
        }
    }

    var stroke: Color {
        switch self {
            case .updateInfo:
                .blue.opacity(0.25)
            case .signOut:
                .red.opacity(0.25)
        }
    }
}

fileprivate enum ThemeButtonTypes: String {
    case bright = "Светлая"
    case dark = "Темная"
    
    var icon: String {
        switch self {
            case .bright:
                return "sun.max.fill"
            case .dark:
                return "moon.fill"
        }
    }
}

#Preview {
    SettingsSheetView(vm: ProfileViewModel(authService: AuthService(),
                                           contentService: ContentService()), isSignedOut: false) {

    } onSignOut: {

    }
}
