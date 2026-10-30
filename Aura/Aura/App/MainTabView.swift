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
    @StateObject private var aiConsentViewModel: AIConsentViewModel

    @State private var selectedTab: Tabs = .home

    private let authService: AuthServiceProtocol
    private let contentService: ContentServiceProtocol

    init(authService: AuthService,
         contentService: ContentService,
         storage: any LocalStorageProtocol = LocalStorage(),
         promptsAIConsentAutomatically: Bool = true) {
        self.authService = authService
        self.contentService = contentService

        _homeViewModel = StateObject(wrappedValue: HomeViewModel(
            authService: authService,
            contentService: contentService,
            storage: storage))
        _compatibilityViewModel = StateObject(wrappedValue: CompatibilityViewModel(
            authService: authService,
            contentService: contentService))
        _historyViewModel = StateObject(wrappedValue: HistoryViewModel(
            authService: authService,
            contentService: contentService,
            storage: storage))
        _profileViewModel = StateObject(wrappedValue: ProfileViewModel(
            authService: authService,
            contentService: contentService,
            storage: storage))
        _aiConsentViewModel = StateObject(wrappedValue: AIConsentViewModel(
            authService: authService,
            promptsAutomatically: promptsAIConsentAutomatically))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: .home) {
                HomeView(vm: homeViewModel) {
                    selectedTab = .compatibility
                } aiConsentButton: {
                    aiConsentViewModel.request()
                }
            } label: {
                Image(systemName: Tabs.home.icon)
            }

            Tab(value: .compatibility) {
                CompatibilityView(vm: compatibilityViewModel) {
                    aiConsentViewModel.request()
                }
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
                            homeViewModel: homeViewModel) {
                    aiConsentViewModel.request()
                }
            } label: {
                Image(systemName: Tabs.profile.icon)
            }
        }
        .tabBarMinimizeBehavior(.never)
        .sheet(isPresented: $aiConsentViewModel.showConsent) {
            AIConsentView(vm: aiConsentViewModel)
        }
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
