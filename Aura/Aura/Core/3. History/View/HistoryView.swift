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
                            LazyVStack {
                                ForEach(vm.historyCells) { item in
                                    historyCell(item)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .refreshable {
                        await vm.fetchHistory()
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
        .loadingCover(isPresented: vm.loadingTitle != nil, title: vm.loadingTitle ?? "")
        .alert(vm.alertMessage, isPresented: $vm.showAlert) {
            Button("OK", role: .cancel) {}
        }
        .alert("Удалить результат?", isPresented: $vm.showDeleteAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Удалить", role: .destructive) {
                vm.deleteRequestedCell()
            }
        } message: {
            Text("Результат теста нельзя будет восстановить")
        }
    }
}

extension HistoryView {
    @ViewBuilder
    private func historyCell(_ item: HistoryCellModel) -> some View {
        Button {
            vm.openHistoryCellDetails(item)
        } label: {
            HistoryCellView(cell: item)
                .frame(maxWidth: .infinity, alignment: .leading)
                .tint(.primaryText)
                .contextMenu {
                    Button("Удалить", role: .destructive) {
                        vm.requestDeletion(item: item)
                    }
                }
        }
    }

    @ViewBuilder
    private func emptyListView() -> some View {
        switch vm.loadState {
            case .loading:
                EmptyView()
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
