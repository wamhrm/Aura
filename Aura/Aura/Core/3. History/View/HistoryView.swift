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
        ZStack {
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
            .opacity(vm.showsLoadingScreen ? 0 : 1)

            ZStack {
                BackgroundView()
                LoadingView(title: vm.isLoading ? "Открываем результат" : "Загружаем историю",
                            isPresented: vm.showsLoadingScreen)
            }
            .opacity(vm.showsLoadingScreen ? 1 : 0)
        }
        .animation(.easeInOut(duration: 0.35), value: vm.showsLoadingScreen)
        .alert(vm.alertMessage, isPresented: $vm.showAlert.removeDuplicates()) {
            Button("OK", role: .cancel) {}
        }
        .alert("Удалить результат?", isPresented: $vm.showDeleteAlert.removeDuplicates()) {
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
