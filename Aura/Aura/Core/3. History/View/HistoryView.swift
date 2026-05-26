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
                                    Button {
                                        vm.openHistoryCellDetails(item)
                                    } label: {
                                        HistoryCellView(cell: item)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .tint(.black)
                                            .contextMenu {
                                                Button("Удалить", role: .destructive) {
                                                    vm.deleteHistoryCell(item)
                                                }
                                            }
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal)
                            }
                            .refreshable {
                                vm.fetchHistory()
                            }
                            .scrollIndicators(.hidden)
                        }
                    }
                } else {
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
