//
//  ProfileView.swift
//  Aura
//
//  Created by wamhrm on 31.03.2026.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var vm: ProfileViewModel

    let aiConsentButton: () -> Void

    var body: some View {
        NavigationStack(path: $vm.profileRoutes) {
            ZStack {
                BackgroundView()

                if let user = vm.user {
                    SignedInView(vm: vm, user: user, aiConsentButton: aiConsentButton)
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
                if let profileForm = vm.profileForm {
                    AddProfileInfoView(vm: profileForm)
                }
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
        SettingsSheetView(vm: vm)
            .presentationDetents([.height(Adaptive.size(470, 490))])
    }
}

#Preview {
    ProfileView(vm: ProfileViewModel(authService: AuthService.preview,
                                     contentService: ContentService.preview)) {

    }
}
