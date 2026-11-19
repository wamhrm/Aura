//
//  MainTabView.swift
//  Aura
//
//  Created by wamhrm on 31.03.2026.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var homeViewModel: HomeViewModel
    @StateObject private var compatibilityViewModel: CompatibilityViewModel
    @StateObject private var historyViewModel: HistoryViewModel
    @StateObject private var profileViewModel: ProfileViewModel

    @Environment(\.locale) private var locale
    @State private var selectedTab: Tabs = .home

    init(authService: AuthService,
         contentService: ContentService) {
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(
            authService: authService,
            contentService: contentService))
        _compatibilityViewModel = StateObject(wrappedValue: CompatibilityViewModel(
            authService: authService,
            contentService: contentService))
        _historyViewModel = StateObject(wrappedValue: HistoryViewModel(
            authService: authService,
            contentService: contentService))
        _profileViewModel = StateObject(wrappedValue: ProfileViewModel(
            authService: authService,
            contentService: contentService))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: .home) {
                HomeView(vm: homeViewModel) {
                    selectedTab = .compatibility
                } aiConsentButton: {
                    showAIConsent()
                }
            } label: {
                Image(systemName: Tabs.home.icon)
            }
            .accessibilityLabel("Главная")

            Tab(value: .compatibility) {
                CompatibilityView(vm: compatibilityViewModel) {
                    showAIConsent()
                }
            } label: {
                Image(systemName: Tabs.compatibility.icon)
            }
            .accessibilityLabel("Совместимость")

            Tab(value: .history) {
                HistoryView(vm: historyViewModel)
            } label: {
                Image(systemName: Tabs.history.icon)
            }
            .accessibilityLabel("История")

            Tab(value: .profile) {
                ProfileView(vm: profileViewModel) {
                    showAIConsent()
                }
            } label: {
                Image(systemName: Tabs.profile.icon)
            }
            .accessibilityLabel("Профиль")
        }
        .tabBarMinimizeBehavior(.never)
        .onChange(of: locale.language.languageCode) {
            homeViewModel.refreshLocalizedContent()
            profileViewModel.refreshLocalizedContent()
        }
    }
}

extension MainTabView {
    private func showAIConsent() {
        selectedTab = .home
        homeViewModel.showAIConsent()
    }
}

fileprivate enum Tabs {
    case home, compatibility, history, profile

    var icon: String {
        switch self {
            case .home: "house"
            case .compatibility: "heart"
            case .history: "clock.arrow.circlepath"
            case .profile: "person"
        }
    }
}

#Preview {
    let services = PreviewServices()
    MainTabView(authService: services.authService,
                contentService: services.contentService)
}
