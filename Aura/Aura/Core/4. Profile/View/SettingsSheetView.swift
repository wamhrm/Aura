//
//  SettingsSheetView.swift
//  Aura
//
//  Created by ddorsat on 07.05.2026.
//

import SwiftUI

struct SettingsSheetView: View {
    @State private var isLightTheme = true
    @State private var selectedAccent = 0
    @Environment(\.dismiss) private var dismiss
    
    let colors: [Color] = [.deepBlue, .softPurple, .red, .teal, .orange]
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 30) {
                VStack(alignment: .leading, spacing: 15) {
                    headerText("Оформление")
                    
                    HStack(spacing: 15) {
                        SettingsSheetThemesButtonView(type: .bright, isSelected: isLightTheme) {
                            isLightTheme = true
                        }
                        
                        SettingsSheetThemesButtonView(type: .dark, isSelected: !isLightTheme) {
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
                
                Button {
                    
                } label: {
                    VStack(alignment: .center) {
                        Text("Выйти")
                            .bold()
                            .foregroundStyle(.red)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(.red.opacity(0.155))
                    .overlay {
                        RoundedRectangle(cornerRadius: 15) .stroke(.red.opacity(0.25), lineWidth: 2)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
            }
            .padding(.horizontal)
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
}

extension SettingsSheetView {
    private func headerText(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
}

#Preview {
    SettingsSheetView()
}
