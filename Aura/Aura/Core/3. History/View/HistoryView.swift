//
//  HistoryView.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var vm: HistoryViewModel

    var body: some View {
        NavigationStack(path: $vm.historyRoutes) {
            ZStack {
                Components.backgroundColor()

                if vm.isSignedIn {
                    VStack(alignment: .leading, spacing: 15) {
                        if vm.historyCells.isEmpty {
                            ContentUnavailableView {
                                Label("История пуста", systemImage: "")
                            }
                        } else {
                            ScrollView {
                                ForEach(vm.historyCells) { item in
                                    HistoryCellView(cell: item)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            vm.openHistoryCellDetails(item)
                                        }
                                        .contextMenu {
                                            Button("Удалить", role: .destructive) {
                                                vm.deleteHistoryCell(item)
                                            }
                                        }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                } else {
                    ContentUnavailableView {
                        Label("Войдите в аккаунт, чтобы видеть историю", systemImage: "")
                    }
                }
            }
            .navigationTitle("История тестов")
            .navigationBarTitleDisplayMode(.inline)
            .bottomAreaPadding()
            .navigationDestination(for: HistoryRoutes.self) { route in
                destinationView(route)
            }
            .alert(vm.errorMessage, isPresented: $vm.showError) {
                Button("OK", role: .cancel) {}
            }
        }
    }
}

extension HistoryView {
    @ViewBuilder
    private func destinationView(_ route: HistoryRoutes) -> some View {
        switch route {
            case .personalityResult(let result):
                PersonalityResultView(result: result)
            case .compatibilityResult(let result):
                CompatibilityResultView(result: result)
        }
    }
}

#Preview {
    HistoryView(vm: HistoryViewModel(authService: AuthService(),
                                     psychologyService: PsychologyService()))
}
