//
//  MainTabView.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tabs = .home
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: .home, role: .none) {
                HomeView()
            } label: {
                Image(systemName: Tabs.home.icon)
            }

            Tab(value: .compatibility, role: .none) {
                CompatibilityView()
            } label: {
                Image(systemName: Tabs.compatibility.icon)
            }
            
            Tab(value: .history, role: .none) {
                HistoryView()
            } label: {
                Image(systemName: Tabs.history.icon)
            }
            
            Tab(value: .profile, role: .none) {
                ProfileView()
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
    MainTabView()
}
    
