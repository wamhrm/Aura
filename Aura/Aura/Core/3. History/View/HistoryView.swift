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
                                }
                                .disabled(vm.isLoading)
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
            }
            .opacity(vm.isLoading || (vm.historyCells.isEmpty && vm.loadState == .loading) ? 0 : 1)
            .allowsHitTesting(!(vm.isLoading || (vm.historyCells.isEmpty && vm.loadState == .loading)))

            ZStack {
                BackgroundView()

                LoadingView(title: vm.isLoading ? "Открываем результат" : "Загружаем историю")
            }
            .opacity(vm.isLoading || (vm.historyCells.isEmpty && vm.loadState == .loading) ? 1 : 0)
            .allowsHitTesting(vm.isLoading || (vm.historyCells.isEmpty && vm.loadState == .loading))
        }
        .animation(.easeInOut(duration: 0.35), value: vm.isLoading)
        .animation(.easeInOut(duration: 0.35), value: vm.loadState)
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
