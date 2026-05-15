//
//  ProfileView.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject private var vm: ProfileViewModel
    private let authService: any AuthServiceProtocol
    private let psychologyService: any PsychologyServiceProtocol

    init(vm: ProfileViewModel,
         authService: any AuthServiceProtocol,
         psychologyService: any PsychologyServiceProtocol) {
        self.vm = vm
        self.authService = authService
        self.psychologyService = psychologyService
    }

    var body: some View {
        NavigationStack(path: $vm.profileRoutes) {
            Group {
                switch vm.authState {
                    case .signedIn(let user):
                        SignedInView(vm: vm, user: user)
                    case .signedOut:
                        SignedOutView(vm: vm)
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
                SettingsSheetView {
                    vm.signOut()
                }
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
                AddProfileInfoView(vm: HomeViewModel(authService: authService,
                                                     psychologyService: psychologyService))
            case .settings:
                EmptyView()
        }
    }
}

#Preview {
    let authService = AuthService()
    let psychologyService = PsychologyService()
    
    ProfileView(vm: ProfileViewModel(authService: authService,
                                     psychologyService: psychologyService),
                authService: authService,
                psychologyService: psychologyService)
}
