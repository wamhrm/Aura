//
//  ProfileView.swift
//  Aura
//
//  Created by wamhrm on 31.03.2026.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var vm: ProfileViewModel
    @ObservedObject var homeViewModel: HomeViewModel

    let aiConsentButton: () -> Void

    var body: some View {
        NavigationStack(path: $vm.profileRoutes) {
            Group {
                switch vm.authState {
                    case .signedIn(let user):
                        SignedInView(vm: vm, user: user, aiConsentButton: aiConsentButton)
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                    case .signedOut:
                        BackgroundView()
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
                vm.openSettings()
            } label: {
                Image(systemName: "gearshape")
            }
        }
    }
    
    private func sheetView() -> some View {
        SettingsSheetView(vm: vm, isSignedOut: vm.isSignedOut)
            .presentationDetents([.height(vm.isSignedOut ? Adaptive.size(300, 320) : Adaptive.size(470, 490))])
    }
}

#Preview {
    let authService = AuthService()
    let contentService = ContentService()
    let homeViewModel = HomeViewModel(authService: authService,
                                      contentService: contentService)

    ProfileView(vm: ProfileViewModel(authService: authService,
                                     contentService: contentService),
                homeViewModel: homeViewModel) {

    }
}
