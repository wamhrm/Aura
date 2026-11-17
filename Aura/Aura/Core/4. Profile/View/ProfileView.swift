//
//  ProfileView.swift
//  Aura
//
//  Created by wamhrm on 31.03.2026.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var vm: ProfileViewModel
    @Environment(\.scenePhase) private var scenePhase
    let aiConsentButton: () -> Void

    var body: some View {
        ZStack {
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
                .sheet(isPresented: $vm.showSettings, onDismiss: vm.openProfileFormIfNeeded) {
                    sheetView()
                }
            }
            .opacity(vm.isSavingProfile ? 0 : 1)

            ZStack {
                BackgroundView()
                LoadingView(title: "Сохраняем...", isPresented: vm.isSavingProfile)
            }
            .opacity(vm.isSavingProfile ? 1 : 0)
        }
        .animation(.easeInOut(duration: 0.35), value: vm.isSavingProfile)
        .onAppear {
            if vm.dailyTip?.isFromToday == false { vm.retryDailyTip() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, vm.dailyTip?.isFromToday == false { vm.retryDailyTip() }
        }
    }
}

extension ProfileView {
    @ViewBuilder
    private func destinationView(_ route: ProfileRoutes) -> some View {
        switch route {
            case .addProfileInfo:
                if let profileForm = vm.profileForm {
                    AddProfileInfoView(vm: profileForm, onSave: vm.saveProfileInfo)
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
            .presentationDetents([.height(Adaptive.size(470, 482, 490))])
    }
}

#Preview {
    ProfileView(vm: ProfileViewModel(authService: AuthService.preview,
                                     contentService: ContentService.preview)) {

    }
}
