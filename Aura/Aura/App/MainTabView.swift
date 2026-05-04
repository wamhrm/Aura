//
//  MainTabView.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tabs = .main
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: .main, role: .none) {
                HomeView()
            } label: {
                Image(systemName: Tabs.main.icon)
            }

            Tab(value: .compability, role: .none) {
                CompabilityView()
            } label: {
                Image(systemName: Tabs.compability.icon)
            }
            
            Tab(value: .profile, role: .none) {
                ProfileView()
            } label: {
                Image(systemName: Tabs.profile.icon)
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

fileprivate enum Tabs {
    case main
    case compability
    case profile
    
    var icon: String {
        switch self {
            case .main: return "house"
            case .compability: return "heart"
            case .profile: return "person"
        }
    }
}

#Preview {
    MainTabView()
}
