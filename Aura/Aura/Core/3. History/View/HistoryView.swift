//
//  HistoryView.swift
//  Aura
//
//  Created by wamhrm on 31.03.2026.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var vm: HistoryViewModel

    var body: some View {
        NavigationStack(path: $vm.historyRoutes) {
            ZStack {
                BackgroundView()

                VStack(alignment: .leading, spacing: 15) {
                    ScrollView {
                        if vm.historyCells.isEmpty {
                            emptyListView()
                                .containerRelativeFrame(.vertical)
                        } else {
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
                    }
                    .refreshable {
                        await vm.fetchHistory()
                    }
                    .overlay {
                        if vm.isLoading {
                            ProgressView()
                        }
                    }
                }
                .bottomAreaPadding(15)
            }
            .navigationTitle("История тестов")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: HistoryRoutes.self) { route in
                destinationView(route)
            }
        }
        .alert(vm.alertMessage, isPresented: $vm.showAlert) {
            Button("OK", role: .cancel) {}
        }
    }
}

extension HistoryView {
    @ViewBuilder
    private func emptyListView() -> some View {
        switch vm.loadState {
            case .loading:
                ProgressView()
            case .loaded:
                ContentUnavailableView {
                    Label("История пуста", systemImage: "")
                }
            case .failed(let message):
                LoadFailedView(message: message) {
                    vm.retry()
                }
                .padding(.horizontal)
        }
    }

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
    HistoryView(vm: HistoryViewModel(authService: AuthService.preview,
                                     contentService: ContentService.preview))
}
