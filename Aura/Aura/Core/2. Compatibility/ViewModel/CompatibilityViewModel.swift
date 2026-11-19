//
//  CompatibilityViewModel.swift
//  Aura
//
//  Created by wamhrm on 18.05.2026.
//

import Combine
import Foundation

enum CompatibilityRoutes: Hashable {
    case testDetails(CompatibilityTestTypes)
    case compatibilityResults
}

@MainActor
final class CompatibilityViewModel: ObservableObject, AlertPresentable {
    @Published var compatibilityRoutes: [CompatibilityRoutes] = []
    @Published private(set) var selectedTests: [CompatibilityTestTypes] = [.astrology, .behavioralPatterns, .attachmentCompatibility]
    @Published var partnerInfo = PartnerInfoModel()
    @Published private(set) var compatibilityResult: CompatibilityResultModel?

    @Published private var alertPresented = false
    @Published var alertMessage = ""
    @Published private(set) var isLoading = false
    @Published private(set) var needsAIConsent = false
    @Published var emailConfirmation: EmailConfirmationViewModel?

    private let authService: any AuthServiceProtocol
    private let contentService: any ContentServiceProtocol
    
    private var currentUser: UserModel?
    private var compatibilityRequestID: UUID?
    private var compatibilityRequestUser: UserModel?
    private var compatibilityRequest: CompatibilityTestRequest?
    private var cancellables = Set<AnyCancellable>()

    var showAlert: Bool {
        get { alertPresented }
        set {
            guard alertPresented != newValue else { return }
            alertPresented = newValue
        }
    }

    init(authService: any AuthServiceProtocol,
         contentService: any ContentServiceProtocol) {
        self.authService = authService
        self.contentService = contentService

        setupSubscriptions()
    }

    private func setupSubscriptions() {
        authService.authStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self, case .signedIn(let user) = $0 else { return }
                currentUser = user
                needsAIConsent = !user.allowsAIAnalysis
                if user.hasConfirmedEmail { emailConfirmation = nil }
                dropSexualTest(partnerBirthDate: partnerInfo.birthDate)
            }
            .store(in: &cancellables)

        $partnerInfo
            .map(\.birthDate)
            .removeDuplicates()
            .sink { [weak self] birthDate in
                self?.dropSexualTest(partnerBirthDate: birthDate)
            }
            .store(in: &cancellables)
    }

    private var offersSexualCompatibility: Bool {
        isSexualCompatibilityAvailable(partnerBirthDate: partnerInfo.birthDate)
    }

    var availableTests: [CompatibilityTestTypes] {
        CompatibilityTestTypes.allCases.filter { $0 != .sexualCompatibility || offersSexualCompatibility }
    }

    private func isSexualCompatibilityAvailable(partnerBirthDate: Date) -> Bool {
        guard let birthDate = currentUser?.dateOfBirth,
              let userDate = BirthDateFormatter.date(string: birthDate),
              BirthDateFormatter.isAdult(date: userDate) else {
            return false
        }
        return BirthDateFormatter.isAdult(date: partnerBirthDate)
    }

    private func dropSexualTest(partnerBirthDate: Date) {
        guard !isSexualCompatibilityAvailable(partnerBirthDate: partnerBirthDate) else { return }
        selectedTests.removeAll { $0 == .sexualCompatibility }
    }

    func showTestDetails(_ test: CompatibilityTestTypes) {
        compatibilityRoutes.append(.testDetails(test))
    }

    func selectAllTests() {
        selectedTests = availableTests
    }

    func isSelected(_ test: CompatibilityTestTypes) -> Bool {
        selectedTests.contains(test)
    }

    func toggleTestSelection(_ test: CompatibilityTestTypes) {
        if test == .sexualCompatibility, !offersSexualCompatibility { return }

        if let index = selectedTests.firstIndex(of: test) {
            guard selectedTests.count > InputLimits.minCompatibilityTests else {
                presentAlert(AppLanguage.text("Нельзя выбрать меньше \(InputLimits.minCompatibilityTests) тестов"))
                return
            }

            selectedTests.remove(at: index)
        } else {
            selectedTests.append(test)
        }
    }

    func makeCompatibilityTest() {
        guard !isLoading else { return }

        if let currentUser, !currentUser.hasConfirmedEmail {
            emailConfirmation = EmailConfirmationViewModel(authService: authService,
                                                           email: currentUser.email ?? "")
            return
        }

        do {
            try validatePartnerInfoForms()
        } catch {
            presentAlert(error.userMessage)
            return
        }

        let tests = selectedTests.filter { availableTests.contains($0) }
        let request = partnerInfo.compatibilityTestRequest(selectedTests: tests)
        let requestID = currentCompatibilityRequestID(for: request)

        isLoading = true
        let sessionID = authService.sessionID

        Task {
            guard sessionID == authService.sessionID else { return }
            let deadline = ContinuousClock.now + .milliseconds(350)

            do {
                let result = try await contentService.makeCompatibilityTest(request: request,
                                                                            requestID: requestID)
                guard sessionID == authService.sessionID else { return }
                compatibilityResult = result
                compatibilityRequestID = nil
                try await Task.sleep(until: deadline, clock: .continuous)
                guard sessionID == authService.sessionID else { return }
                compatibilityRoutes.append(.compatibilityResults)
                TestCompletionSound.play()
                try await Task.sleep(for: .milliseconds(50))
                guard sessionID == authService.sessionID else { return }
                partnerInfo = PartnerInfoModel()
            } catch {
                guard sessionID == authService.sessionID else { return }
                presentAlert(error.userMessage)
            }

            guard sessionID == authService.sessionID else { return }
            isLoading = false
        }
    }

    private func currentCompatibilityRequestID(for request: CompatibilityTestRequest) -> UUID {
        if let compatibilityRequestID,
           compatibilityRequestUser == signedInUser,
           compatibilityRequest == request {
            return compatibilityRequestID
        }

        let requestID = UUID()
        compatibilityRequestID = requestID
        compatibilityRequestUser = signedInUser
        compatibilityRequest = request
        return requestID
    }

    private var signedInUser: UserModel? {
        if case .signedIn(let user) = authService.authState { return user }
        return nil
    }

    private func validatePartnerInfoForms() throws {
        let name = partnerInfo.name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard name.count >= InputLimits.minNameLength else {
            throw PartnerInfoError.invalidName
        }
        guard name.count <= InputLimits.maxNameLength else {
            throw PartnerInfoError.nameTooLong
        }
    }
}

fileprivate enum PartnerInfoError: LocalizedError {
    case invalidName, nameTooLong

    var errorDescription: String? {
        switch self {
            case .invalidName: AppLanguage.text("Имя партнёра должно содержать минимум \(InputLimits.minNameLength) символа")
            case .nameTooLong: AppLanguage.text("Имя партнёра должно быть не длиннее \(InputLimits.maxNameLength) символов")
        }
    }
}
