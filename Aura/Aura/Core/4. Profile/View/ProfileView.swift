//
//  ProfileView.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var vm = ProfileViewModel()
    
    var body: some View {
        NavigationStack(path: $vm.profileRoutes) {
            Group {
                if case .signedIn(_) = vm.authState {
                    SignedOutView(vm: vm)
                } else {
                    SignedInView(vm: vm, user: .mock)
                }
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: ProfileRoutes.self) { destination in
                destinationView(destination)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vm.showSettings.toggle()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $vm.showSettings) {
                SettingsSheetView()
                    .presentationDetents([.height(380)])
            }
        }
    }
}

extension ProfileView {
    @ViewBuilder
    private func destinationView(_ route: ProfileRoutes) -> some View {
        switch route {
            case .completeProfile:
                AddProfileInfoView(vm: HomeViewModel())
            case .settings:
                EmptyView()
        }
    }
}

#Preview {
    ProfileView()
}
