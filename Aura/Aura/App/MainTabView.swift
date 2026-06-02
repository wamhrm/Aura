//
//  MainTabView.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var homeViewModel: HomeViewModel
    @StateObject private var compatibilityViewModel: CompatibilityViewModel
    @StateObject private var historyViewModel: HistoryViewModel
    @StateObject private var profileViewModel: ProfileViewModel

    @State private var selectedTab: Tabs = .home

    private let authService: AuthServiceProtocol
    private let contentService: ContentServiceProtocol

    init(authService: AuthService,
         contentService: ContentService) {
        self.authService = authService
        self.contentService = contentService

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
                HomeView(vm: homeViewModel,
                         authService: authService) {
                    selectedTab = .compatibility
                } profileButton: {
                    selectedTab = .profile
                }
            } label: {
                Image(systemName: Tabs.home.icon)
            }

            Tab(value: .compatibility) {
                CompatibilityView(vm: compatibilityViewModel)
            } label: {
                Image(systemName: Tabs.compatibility.icon)
            }

            Tab(value: .history) {
                HistoryView(vm: historyViewModel)
            } label: {
                Image(systemName: Tabs.history.icon)
            }

            Tab(value: .profile) {
                ProfileView(vm: profileViewModel,
                            homeViewModel: homeViewModel)
            } label: {
                Image(systemName: Tabs.profile.icon)
            }
        }
        .disabled(profileViewModel.isLoading)
        .tabBarMinimizeBehavior(.never)
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
    MainTabView(authService: AuthService(),
                contentService: ContentService())
}
