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
                BackgroundView()

                if vm.isServerWakingUp {
                    ServerWakingUpView(isVisible: vm.isServerWakingUp)
                } else if vm.isSignedIn {
                    VStack(alignment: .leading, spacing: 15) {
                        if vm.historyCells.isEmpty {
                            ContentUnavailableView {
                                Label("История пуста", systemImage: "")
                            }
                        } else {
                            ScrollView {
                                ForEach(vm.historyCells) { item in
                                    Button {
                                        vm.openHistoryCellDetails(item)
                                    } label: {
                                        HistoryCellView(cell: item)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .tint(.primaryText)
                                            .contextMenu {
                                                Button("Удалить", role: .destructive) {
                                                    vm.deleteHistoryCell(item)
                                                }
                                            }
                                    }
                                }
                                .disabled(vm.isLoading)
                                .padding(.horizontal)
                            }
                            .refreshable {
                                vm.fetchHistory()
                            }
                            .overlay {
                                if vm.isLoading {
                                    ProgressView()
                                }
                            }
                        }
                    }
                    .bottomAreaPadding(15)
                } else if !vm.isSignedIn {
                    ContentUnavailableView {
                        Label("Войдите в аккаунт, чтобы видеть историю", systemImage: "")
                    }
                    .padding(.bottom, 35)
                }
            }
            .navigationTitle("История тестов")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: HistoryRoutes.self) { route in
                destinationView(route)
            }
            .animation(.easeInOut(duration: 0.25), value: vm.isServerWakingUp)
            .alert(vm.alertMessage, isPresented: $vm.showAlert) {
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
                                     contentService: ContentService()))
}
