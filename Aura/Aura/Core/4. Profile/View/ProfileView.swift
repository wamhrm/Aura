//
//  ProfileView.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject private var vm: ProfileViewModel
    @ObservedObject private var homeViewModel: HomeViewModel

    init(vm: ProfileViewModel, homeViewModel: HomeViewModel) {
        self.vm = vm
        self.homeViewModel = homeViewModel
    }

    var body: some View {
        NavigationStack(path: $vm.profileRoutes) {
            Group {
                switch vm.authState {
                    case .signedIn(let user):
                        SignedInView(vm: vm, user: user)
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                    case .signedOut:
                        SignedOutView(vm: vm)
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                }
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: ProfileRoutes.self) { destination in
                destinationView(destination)
            }
            .toolbar {
                toolbarItem()
            }
            .sheet(isPresented: $vm.showSettings) {
                sheetView()
            }
        }
    }
}

extension ProfileView {
    @ViewBuilder
    private func destinationView(_ route: ProfileRoutes) -> some View {
        switch route {
            case .addProfileInfo:
                AddProfileInfoView(vm: homeViewModel)
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarItem() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                vm.showSettings.toggle()
            } label: {
                Image(systemName: "gearshape")
            }
        }
    }
    
    private func sheetView() -> some View {
        SettingsSheetView(vm: vm, isSignedOut: vm.isSignedOut) {
            vm.profileRoutes.append(.addProfileInfo)
        } onSignOut: {
            vm.signOut()
        }
        .presentationDetents([.height(vm.isSignedOut ? Components.displaySize(260, 280) : Components.displaySize(370, 390))])
    }
}

#Preview {
    let authService = AuthService()
    let contentService = ContentService()
    let homeViewModel = HomeViewModel(authService: authService,
                                      contentService: contentService)

    ProfileView(vm: ProfileViewModel(authService: authService,
                                     contentService: contentService),
                homeViewModel: homeViewModel)
}
