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
    @State private var isLightTheme = true
    @State private var selectedAccent = 0
    @Environment(\.dismiss) private var dismiss
    let onUpdateInfo: () -> Void
    let onSignOut: () -> Void

    let colors: [Color] = [.deepBlue, .softPurple, .red, .teal, .orange]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 30) {
                VStack(alignment: .leading, spacing: 15) {
                    headerText("Оформление")

                    HStack(spacing: 15) {
                        SettingsSheetThemesButtonView(type: .bright,
                                                      isSelected: isLightTheme) {
                            isLightTheme = true
                        }

                        SettingsSheetThemesButtonView(type: .dark,
                                                      isSelected: !isLightTheme) {
                            isLightTheme = false
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 15) {
                    headerText("Акцентный цвет")

                    HStack {
                        ForEach(0..<colors.count, id: \.self) { index in
                            SettingsAccentColorView(color: colors[index],
                                                    isSelected: selectedAccent == index) {
                                selectedAccent = index
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
    private func headerText(_ title: String) -> some View {
        Text(title)
            .font(Components.isRegular(.footnote, .callout))
            .foregroundStyle(.secondary)
    }

    private func customButton(_ type: SettingsSheetButtonType, _ completion: @escaping () -> Void) -> some View {
        Button {
            completion()
        } label: {
            VStack(alignment: .center) {
                Text(type.rawValue)
                    .font(Components.isRegular(.footnote, .callout))
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
}

enum SettingsSheetButtonType: String {
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

#Preview {
    SettingsSheetView(vm: ProfileViewModel(authService: AuthService(),
                                           contentService: ContentService()), isSignedOut: false) {

    } onSignOut: {

    }
}
