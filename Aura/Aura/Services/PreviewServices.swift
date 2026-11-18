//
//  PreviewServices.swift
//  Aura
//
//  Created by wamhrm on 18.11.2026.
//

import Foundation
import Synchronization

struct PreviewServices {
    let authService: AuthService
    let contentService: ContentService

    init(signedIn: Bool = true) {
        let networkService = PreviewNetworkService()
        authService = AuthService.preview(networkService: networkService, signedIn: signedIn)
        contentService = ContentService(networkService: networkService, authService: authService)
    }
}

struct PreviewNetworkService: NetworkServiceProtocol {
    let session = AuthTokenResponse(token: "preview-session", user: .mock)

    private let historyEntry = HistoryCellModel(
        id: UUID(),
        kind: .personality,
        createdAt: "2026-11-18T12:00:00Z",
        selectedTests: PersonalityResultModel.mock.selectedTests.map(\.rawValue),
        archetypeTitle: PersonalityResultModel.mock.archetypeTitle,
        archetypeSubtitle: PersonalityResultModel.mock.archetypeSubtitle,
        zodiacSign: PersonalityResultModel.mock.zodiacSign,
        compatibilityScore: nil,
        partnerName: nil,
        partnerZodiacSign: nil,
        personalityResult: .mock,
        compatibilityResult: nil)

    func fetchCurrentUser() async throws -> UserModel { session.user }
    func createAccount(name: String, email: String, password: String) async throws -> AuthTokenResponse { session }
    func ensureEmailAvailable(email: String) async throws {}
    func signIn(email: String, password: String) async throws -> AuthTokenResponse { session }
    func logout() async throws {}
    func requestPasswordReset(email: String) async throws {}
    func resetPassword(email: String, code: String, password: String) async throws -> AuthTokenResponse { session }
    func deleteAccount() async throws {}
    func giveAIConsent() async throws -> UserModel { session.user }
    func sendEmailConfirmationCode() async throws {}
    func confirmEmail(code: String) async throws -> UserModel { session.user }
    func updateProfileInfo(_ profileInfo: ProfileInfoModel) async throws -> UserModel { session.user }
    func fetchCurrentHoroscope() async throws -> HoroscopeModel { .mock }
    func fetchDailyInsight() async throws -> DailyContentModel { dailyContent(text: "Найдите время для того, что помогает вам восстановиться.") }
    func fetchDailyTip() async throws -> DailyContentModel { dailyContent(text: "Начните день с одного дела, которое давно откладывали.") }
    func makePersonalityTest(selectedTests: [PersonalityTestTypes], requestID: UUID) async throws -> PersonalityResultModel { .mock }
    func makeCompatibilityTest(_ testRequest: CompatibilityTestRequest, requestID: UUID) async throws -> CompatibilityResultModel { .mock }
    func fetchHistory() async throws -> [HistoryCellModel] { [historyEntry] }

    func fetchHistoryDetails(id: UUID) async throws -> HistoryCellModel {
        guard id == historyEntry.id else { throw NetworkError.notFound }
        return historyEntry
    }

    func deleteHistory(id: UUID) async throws {
        throw NetworkError.server("History deletion is unavailable in previews.")
    }

    private func dailyContent(text: String) -> DailyContentModel {
        let format = Date.ISO8601FormatStyle(timeZone: .current).year().month().day().dateSeparator(.dash)
        return DailyContentModel(id: UUID(), text: text, dateCreated: Date().formatted(format))
    }
}

extension AuthService {
    static func preview(networkService: PreviewNetworkService = PreviewNetworkService(),
                        signedIn: Bool = false) -> AuthService {
        let service = AuthService(networkService: networkService, keychain: PreviewKeychain(), userDefaults: nil)
        if signedIn {
            try? service.startSession(response: networkService.session)
            service.finishOnboarding()
        }
        return service
    }
}

nonisolated final class PreviewKeychain: KeychainHelperProtocol {
    private let token = Mutex<Data?>(nil)

    func saveToken(_ data: Data, path: String, key: String) throws {
        token.withLock { $0 = data }
    }

    func getToken(path: String, key: String) throws -> Data? {
        token.withLock { $0 }
    }

    func deleteToken(path: String, key: String) throws {
        token.withLock { $0 = nil }
    }
}
