//
//  MainTabView.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import SwiftUI

struct MainTabView: View {
    private let authService: AuthServiceProtocol
    private let psychologyService: PsychologyServiceProtocol
    
    @StateObject private var homeViewModel: HomeViewModel
    @StateObject private var compatibilityViewModel: CompatibilityViewModel
    @StateObject private var profileViewModel: ProfileViewModel
    @StateObject private var historyViewModel: HistoryViewModel
    
    @State private var selectedTab: Tabs = .home
    
    init(authService: AuthService,
         psychologyService: PsychologyService) {
        self.authService = authService
        self.psychologyService = psychologyService
        
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(
            authService: authService,
            psychologyService: psychologyService))
        _compatibilityViewModel = StateObject(wrappedValue: CompatibilityViewModel(
            psychologyService: psychologyService))
        _profileViewModel = StateObject(wrappedValue: ProfileViewModel(
            authService: authService,
            psychologyService: psychologyService))
        _historyViewModel = StateObject(wrappedValue: HistoryViewModel(
            authService: authService,
            psychologyService: psychologyService))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: .home, role: .none) {
                HomeView(vm: homeViewModel,
                         authService: authService,
                         psychologyService: psychologyService) {
                    selectedTab = .compatibility
                } profileButton: {
                    selectedTab = .profile
                }
            } label: {
                Image(systemName: Tabs.home.icon)
            }

            Tab(value: .compatibility, role: .none) {
                CompatibilityView(vm: compatibilityViewModel)
            } label: {
                Image(systemName: Tabs.compatibility.icon)
            }

            Tab(value: .history, role: .none) {
                HistoryView(vm: historyViewModel)
            } label: {
                Image(systemName: Tabs.history.icon)
            }

            Tab(value: .profile, role: .none) {
                ProfileView(vm: profileViewModel,
                            homeViewModel: homeViewModel)
            } label: {
                Image(systemName: Tabs.profile.icon)
            }
        }
        .tabBarMinimizeBehavior(.never)
    }
}

fileprivate enum Tabs {
    case home, compatibility, history, profile

    var icon: String {
        switch self {
            case .home:
                return "house"
            case .compatibility:
                return "heart"
            case .history:
                return "clock.arrow.circlepath"
            case .profile:
                return "person"
        }
    }
}

#Preview {
    MainTabView(authService: AuthService(), psychologyService: PsychologyService())
}

