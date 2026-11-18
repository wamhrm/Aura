//
//  AuthServiceTests.swift
//  AuraUnitTests
//
//  Created by wamhrm on 06.11.2026.
//

import Combine
import Foundation
import Security
import XCTest
@testable import Aura

@MainActor
final class AuthServiceTests: AuraUnitTestCase {
    func test_previews_restoreAndLoadContentWithIndependentSessions() async throws {
        let welcome = PreviewServices(signedIn: false)
        let signedIn = PreviewServices()

        await welcome.authService.restoreSession()

        XCTAssertEqual(welcome.authService.restorationState, .loaded)
        XCTAssertNil(currentUser(welcome.authService))
        XCTAssertEqual(currentUser(signedIn.authService), .mock)

        try await welcome.authService.signIn(email: "preview@example.test", password: "preview-password")
        try await welcome.authService.signOut()
        try await signedIn.contentService.fetchHistory()
        let insight = try await signedIn.contentService.fetchDailyInsight()

        XCTAssertNil(currentUser(welcome.authService))
        XCTAssertEqual(currentUser(signedIn.authService), .mock)
        XCTAssertEqual(signedIn.contentService.historyCells.value.first?.personalityResult, .mock)
        XCTAssertTrue(insight.isFromToday)
    }

    func test_networkRequest_propagatesAnUnreadableKeychain() async {
        let keychain = MockKeychainHelper()
        keychain.readFails = true
        let network = NetworkService(baseURL: "http://127.0.0.1:1", keychain: keychain)

        do {
            _ = try await network.fetchHistory()
            XCTFail("The unreadable token must fail before sending a request")
        } catch {
            XCTAssertEqual((error as? KeychainError)?.status, errSecInteractionNotAllowed)
        }
    }

    func test_storedToken_isOnlyUsedForProtectedRequests() async throws {
        let keychain = MockKeychainHelper()
        try keychain.saveAuthToken("stale-token")
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [UnauthorizedResponse.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let network = NetworkService(baseURL: "https://aura.example.test", session: session, keychain: keychain)

        do {
            _ = try await network.signIn(email: "anna@example.test", password: "wrong-password")
            XCTFail("Expected the sign-in error")
        } catch NetworkError.server(let reason) {
            XCTAssertEqual(reason, "Неверная почта или пароль")
        }

        do {
            _ = try await network.fetchCurrentUser()
            XCTFail("Expected the session expiration error")
        } catch NetworkError.sessionExpired {
        }
    }

    func test_generatedResults_doNotWaitForTheHistoryRefresh() async throws {
        let network = MockNetworkService()
        let auth = MockAuthService(user: makeUser())
        let content = ContentService(networkService: network, authService: auth)
        var releaseHistory = false
        var historyStarted = false
        network.beforeHistoryResponse = {
            historyStarted = true
            await waitUntil { releaseHistory }
        }

        let personality = try await content.makePersonalityTest(selectedTests: [.astrology], requestID: UUID())
        let compatibility = try await content.makeCompatibilityTest(request: PartnerInfoModel().compatibilityTestRequest(selectedTests: [.astrology]), requestID: UUID())
        releaseHistory = true
        await waitUntil { historyStarted }

        XCTAssertEqual(personality, .mock)
        XCTAssertEqual(compatibility, .mock)
    }

    func test_historyFetch_startedBeforeDeletion_doesNotRestoreTheDeletedEntry() async throws {
        let network = MockNetworkService()
        let content = ContentService(networkService: network, authService: MockAuthService(user: makeUser()))
        let entry = HistoryCellModel.personalityPlaceholder
        network.history = [entry]
        try await content.fetchHistory()
        XCTAssertEqual(content.historyCells.value, [entry])

        var started = false
        var release = false
        network.beforeHistoryResponse = {
            started = true
            await waitUntil { release }
        }
        let oldFetch = Task { try await content.fetchHistory() }
        await waitUntil { started }

        network.beforeHistoryResponse = nil
        try await content.deleteHistory(id: entry.id)
        var shownEntries: [HistoryCellModel] = []
        let subscription = content.historyCells.sink { shownEntries.append(contentsOf: $0) }
        defer { subscription.cancel() }
        release = true
        try await oldFetch.value

        XCTAssertTrue(shownEntries.isEmpty)
        XCTAssertEqual(content.historyState.value, .loaded)
    }

    func test_historyFetchFailure_afterNewerSuccess_doesNotReplaceTheLoadedState() async throws {
        let network = MockNetworkService()
        let content = ContentService(networkService: network, authService: MockAuthService(user: makeUser()))
        var started = false
        var release = false
        network.beforeHistoryResponse = {
            started = true
            await waitUntil { release }
            throw serverError
        }
        let oldFetch = Task { try await content.fetchHistory() }
        await waitUntil { started }

        network.beforeHistoryResponse = nil
        try await content.fetchHistory()
        release = true
        try await oldFetch.value

        XCTAssertTrue(content.historyCells.value.isEmpty)
        XCTAssertEqual(content.historyState.value, .loaded)
    }

    func test_failedTokenSave_doesNotSignInOrSaveUser() async {
        // Given
        let keychain = MockKeychainHelper()
        keychain.saveFails = true
        let storage = makeStorage()
        let auth = AuthService(networkService: MockNetworkService(), keychain: keychain, userDefaults: storage.defaults)

        // When
        do {
            try await auth.signIn(email: "test@test.com", password: "password")
            XCTFail("Saving the token must fail")
        } catch {
            XCTAssertEqual((error as? KeychainError)?.status, errSecInteractionNotAllowed)
            XCTAssertEqual(error.userMessage, "Данные входа недоступны. Разблокируйте устройство и попробуйте ещё раз")
        }

        // Then
        guard case .signedOut = auth.authState else { return XCTFail("Unexpected signed-in session") }
        XCTAssertNil(storage.defaults.object(forKey: Constants.userKey))
    }

    func test_successfulSignIn_savesOnlyToken_andKeepsUserInMemory() async throws {
        // Given
        let keychain = MockKeychainHelper()
        let storage = makeStorage()
        let network = MockNetworkService()
        let auth = AuthService(networkService: network, keychain: keychain, userDefaults: storage.defaults)

        // When
        try await auth.signIn(email: "test@test.com", password: "password")

        // Then
        XCTAssertEqual(try keychain.loadAuthToken(), "new-token")
        XCTAssertEqual(currentUser(auth), network.user)
        XCTAssertNil(storage.defaults.object(forKey: Constants.userKey))
        guard case .signedIn(let user) = auth.authState else { return XCTFail("No session") }
        XCTAssertEqual(user, network.user)
    }

    func test_failedTokenDeletion_keepsSessionAndToken() async throws {
        let keychain = MockKeychainHelper()
        let storage = makeStorage()
        let network = MockNetworkService()
        let auth = AuthService(networkService: network, keychain: keychain, userDefaults: storage.defaults)
        try await auth.signIn(email: "test@test.com", password: "password")
        keychain.deleteFails = true

        do {
            try await auth.signOut()
            XCTFail("Sign-out must fail")
        } catch {
            XCTAssertEqual((error as? KeychainError)?.status, errSecInteractionNotAllowed)
        }

        XCTAssertEqual(try keychain.loadAuthToken(), "new-token")
        XCTAssertEqual(currentUser(auth), network.user)
        XCTAssertNil(storage.defaults.object(forKey: Constants.userKey))
        guard case .signedIn = auth.authState else { return XCTFail("Failed sign-out ended the session") }
    }

    func test_successfulSignOut_removesTokenAndUserFromMemory() async throws {
        let keychain = MockKeychainHelper()
        let storage = makeStorage()
        let auth = AuthService(networkService: MockNetworkService(), keychain: keychain, userDefaults: storage.defaults)
        try await auth.signIn(email: "test@test.com", password: "password")

        try await auth.signOut()

        XCTAssertNil(try keychain.loadAuthToken())
        XCTAssertNil(storage.defaults.object(forKey: Constants.userKey))
        guard case .signedOut = auth.authState else { return XCTFail("Session was not ended") }
    }

    func test_tokenAlone_restoresCurrentUserFromTheServer() async throws {
        let keychain = MockKeychainHelper()
        try keychain.saveAuthToken("saved-token")
        let storage = makeStorage()
        let network = MockNetworkService()
        let auth = AuthService(networkService: network, keychain: keychain, userDefaults: storage.defaults)

        await auth.restoreSession()

        XCTAssertEqual(try keychain.loadAuthToken(), "saved-token")
        XCTAssertEqual(currentUser(auth), network.user)
        XCTAssertTrue(auth.showsMainScreen)
        XCTAssertEqual(auth.restorationState, .loaded)
        XCTAssertEqual(network.currentUserCount, 1)
        XCTAssertNil(storage.defaults.object(forKey: Constants.userKey))

        await auth.restoreSession()
        XCTAssertEqual(network.currentUserCount, 1)
    }

    func test_launch_removesOldProfile_andPreservesAppearance() async throws {
        let storage = makeStorage()
        storage.defaults.set(try JSONEncoder().encode(makeUser(name: "Старое имя")), forKey: Constants.userKey)
        storage.defaults.set("dark", forKey: Constants.selectedThemeKey)
        storage.defaults.set("blue", forKey: Constants.accentColorKey)
        let keychain = MockKeychainHelper()
        try keychain.saveAuthToken("saved-token")
        let network = MockNetworkService()
        let auth = AuthService(networkService: network, keychain: keychain, userDefaults: storage.defaults)

        await auth.restoreSession()

        XCTAssertEqual(currentUser(auth), network.user)
        XCTAssertNil(storage.defaults.object(forKey: Constants.userKey))
        XCTAssertEqual(storage.defaults.string(forKey: Constants.selectedThemeKey), "dark")
        XCTAssertEqual(storage.defaults.string(forKey: Constants.accentColorKey), "blue")
        XCTAssertEqual(try keychain.loadAuthToken(), "saved-token")
    }

    func test_unavailableKeychain_showsRestorationError_withoutFetchingUser() async throws {
        let keychain = MockKeychainHelper()
        try keychain.saveAuthToken("saved-token")
        keychain.readFails = true
        let storage = makeStorage()
        let network = MockNetworkService()
        let auth = AuthService(networkService: network, keychain: keychain, userDefaults: storage.defaults)

        await auth.restoreSession()

        XCTAssertEqual(auth.restorationState, .failed("Данные входа недоступны. Разблокируйте устройство и попробуйте ещё раз"))
        XCTAssertNil(currentUser(auth))
        XCTAssertEqual(network.currentUserCount, 0)
        keychain.readFails = false
        XCTAssertEqual(try keychain.loadAuthToken(), "saved-token")
    }

    func test_restoreFailure_keepsToken_andCanBeRetriedOnce() async throws {
        let keychain = MockKeychainHelper()
        try keychain.saveAuthToken("saved-token")
        let network = MockNetworkService()
        network.errorToThrow = serverError
        let storage = makeStorage()
        let auth = AuthService(networkService: network, keychain: keychain, userDefaults: storage.defaults)

        await auth.restoreSession()

        XCTAssertEqual(auth.restorationState, .failed("Ошибка сервера"))
        XCTAssertNil(currentUser(auth))
        XCTAssertEqual(try keychain.loadAuthToken(), "saved-token")

        network.errorToThrow = nil
        auth.retryRestoreSession()
        auth.retryRestoreSession()
        await waitUntil { auth.restorationState == .loaded }

        XCTAssertEqual(currentUser(auth), network.user)
        XCTAssertEqual(network.currentUserCount, 2)
    }

    func test_rejectedStoredToken_returnsToSignIn() async throws {
        let keychain = MockKeychainHelper()
        try keychain.saveAuthToken("saved-token")
        let network = MockNetworkService()
        network.errorToThrow = NetworkError.sessionExpired
        let storage = makeStorage()
        let auth = AuthService(networkService: network, keychain: keychain, userDefaults: storage.defaults)

        await auth.restoreSession()

        XCTAssertEqual(auth.restorationState, .loaded)
        XCTAssertNil(try keychain.loadAuthToken())
        XCTAssertNil(currentUser(auth))
        XCTAssertFalse(auth.showsMainScreen)
        XCTAssertEqual(auth.takeExpiredSessionMessage(), "Сессия истекла. Войдите снова")
    }

    func test_rejectedStoredToken_returnsToSignIn_whenTokenDeletionFails() async throws {
        let keychain = MockKeychainHelper()
        try keychain.saveAuthToken("saved-token")
        keychain.deleteFails = true
        let network = MockNetworkService()
        network.errorToThrow = NetworkError.sessionExpired
        let storage = makeStorage()
        let auth = AuthService(networkService: network, keychain: keychain, userDefaults: storage.defaults)

        await auth.restoreSession()

        XCTAssertEqual(auth.restorationState, .loaded)
        XCTAssertEqual(try keychain.loadAuthToken(), "saved-token")
        XCTAssertNil(currentUser(auth))
        XCTAssertNil(auth.sessionID)
        XCTAssertEqual(auth.takeExpiredSessionMessage(), "Сессия истекла. Войдите снова")
    }

    func test_lateRestorationResponse_cannotRestoreAnEndedSession() async throws {
        let keychain = MockKeychainHelper()
        try keychain.saveAuthToken("saved-token")
        let network = MockNetworkService()
        let storage = makeStorage()
        let auth = AuthService(networkService: network, keychain: keychain, userDefaults: storage.defaults)
        network.beforeCurrentUserResponse = { auth.endExpiredSession() }

        await auth.restoreSession()

        XCTAssertNil(currentUser(auth))
        XCTAssertNil(try keychain.loadAuthToken())
        XCTAssertEqual(auth.restorationState, .loaded)
    }

    func test_launch_showsMainScreen_onlyWithACompleteProfile() async throws {
        // Given / When
        let complete = try await makeStoredAuth(user: makeUser())
        let incomplete = try await makeStoredAuth(user: makeUser(dateOfBirth: nil))
        let signedOut = try await makeStoredAuth(user: nil)

        // Then
        XCTAssertTrue(complete.showsMainScreen)
        XCTAssertFalse(incomplete.showsMainScreen)
        XCTAssertFalse(signedOut.showsMainScreen)
    }

    func test_signIn_staysInOnboarding_untilItFinishes() async throws {
        // Given
        let auth = try await makeStoredAuth(user: nil)

        // When
        try await auth.signIn(email: "test@test.com", password: "password")

        // Then
        XCTAssertFalse(auth.showsMainScreen)

        // When the onboarding flow finishes
        auth.finishOnboarding()

        // Then
        XCTAssertTrue(auth.showsMainScreen)
        try await auth.signOut()
        XCTAssertFalse(auth.showsMainScreen)
    }

    private func currentUser(_ auth: AuthService) -> UserModel? {
        if case .signedIn(let user) = auth.authState { return user }
        return nil
    }

    private func makeStoredAuth(user: UserModel?) async throws -> AuthService {
        let keychain = MockKeychainHelper()
        let storage = makeStorage()
        let network = MockNetworkService()

        if let user {
            try keychain.saveAuthToken("saved-token")
            network.user = user
        }

        let auth = AuthService(networkService: network, keychain: keychain, userDefaults: storage.defaults)
        await auth.restoreSession()
        return auth
    }

    func test_profileConsentAndConfirmation_updateUserOnlyInMemory() async throws {
        // Given
        let keychain = MockKeychainHelper()
        let storage = makeStorage()
        let network = MockNetworkService()
        let auth = AuthService(networkService: network, keychain: keychain, userDefaults: storage.defaults)
        try await auth.signIn(email: "test@test.com", password: "password")
        let sessionID = auth.sessionID

        // When the profile is saved
        let saved = makeUser(dateOfBirth: "20.01.1990", hasAIConsent: false, isEmailConfirmed: false)
        network.user = saved
        try await auth.updateProfileInfo(ProfileInfoModel())

        // Then
        XCTAssertEqual(currentUser(auth), saved)
        XCTAssertNil(storage.defaults.object(forKey: Constants.userKey))

        // When consent and confirmation return the next user
        let confirmed = makeUser(dateOfBirth: "01.01.2001", hasAIConsent: true, isEmailConfirmed: true)
        network.user = confirmed
        try await auth.giveAIConsent()
        try await auth.confirmEmail(code: "123456")

        // Then
        XCTAssertEqual(currentUser(auth), confirmed)
        XCTAssertNil(storage.defaults.object(forKey: Constants.userKey))
        XCTAssertEqual(auth.sessionID, sessionID)
        guard case .signedIn(let user) = auth.authState else { return XCTFail("No session") }
        XCTAssertEqual(user, confirmed)
    }

    func test_profileResponse_afterSessionEnd_doesNotRestoreUser() async throws {
        let keychain = MockKeychainHelper()
        let storage = makeStorage()
        let network = MockNetworkService()
        let auth = AuthService(networkService: network, keychain: keychain, userDefaults: storage.defaults)
        try await auth.signIn(email: "test@test.com", password: "password")
        network.beforeProfileResponse = { auth.endExpiredSession() }

        do {
            try await auth.updateProfileInfo(ProfileInfoModel())
            XCTFail("An ended session must reject the response")
        } catch {
            guard case NetworkError.cancelled = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }

        XCTAssertNil(try keychain.loadAuthToken())
        XCTAssertNil(storage.defaults.object(forKey: Constants.userKey))
        guard case .signedOut = auth.authState else { return XCTFail("Session was restored") }
    }

    func test_contentResponse_afterSessionEnd_keepsContentCleared() async throws {
        let keychain = MockKeychainHelper()
        let storage = makeStorage()
        let network = MockNetworkService()
        let auth = AuthService(networkService: network, keychain: keychain, userDefaults: storage.defaults)
        try await auth.signIn(email: "test@test.com", password: "password")
        let content = ContentService(networkService: network, authService: auth)
        network.history = [.personalityPlaceholder]
        network.beforeHistoryResponse = { auth.endExpiredSession() }

        do {
            try await content.fetchHistory()
            XCTFail("An ended session must reject the response")
        } catch {
            guard case NetworkError.cancelled = error else { return XCTFail("Unexpected error: \(error)") }
        }

        XCTAssertTrue(content.historyCells.value.isEmpty)
        XCTAssertNil(auth.sessionID)
        XCTAssertNil(storage.defaults.object(forKey: Constants.userKey))
    }

    func test_contentResponse_afterAnotherSignIn_doesNotPublishOldHistory() async throws {
        for nextUser in [makeUser(), makeUser(id: UUID(), name: "Мария")] {
            let storage = makeStorage()
            let network = MockNetworkService()
            let auth = AuthService(networkService: network, keychain: MockKeychainHelper(), userDefaults: storage.defaults)
            try await auth.signIn(email: "test@test.com", password: "password")
            let content = ContentService(networkService: network, authService: auth)
            let previousSession = auth.sessionID
            network.history = [.personalityPlaceholder]
            network.beforeHistoryResponse = {
                network.user = nextUser
                try await auth.signIn(email: "next@test.com", password: "password")
            }

            do {
                try await content.fetchHistory()
                XCTFail("A new sign-in must reject the old response")
            } catch {
                guard case NetworkError.cancelled = error else { return XCTFail("Unexpected error: \(error)") }
            }

            XCTAssertNotEqual(auth.sessionID, previousSession)
            XCTAssertEqual(currentUser(auth), nextUser)
            XCTAssertNil(storage.defaults.object(forKey: Constants.userKey))
            XCTAssertTrue(content.historyCells.value.isEmpty)
        }
    }

    func test_confirmationResponse_afterSessionEnd_doesNotRestoreUser() async throws {
        let keychain = MockKeychainHelper()
        let storage = makeStorage()
        let network = MockNetworkService()
        let auth = AuthService(networkService: network, keychain: keychain, userDefaults: storage.defaults)
        try await auth.signIn(email: "test@test.com", password: "password")
        network.beforeConfirmationResponse = { auth.endExpiredSession() }

        do {
            try await auth.confirmEmail(code: "123456")
            XCTFail("An ended session must reject confirmation")
        } catch {
            guard case NetworkError.cancelled = error else { return XCTFail("Unexpected error: \(error)") }
        }

        XCTAssertNil(auth.sessionID)
        XCTAssertNil(try keychain.loadAuthToken())
        XCTAssertNil(storage.defaults.object(forKey: Constants.userKey))
        guard case .signedOut = auth.authState else { return XCTFail("Session was restored") }
    }

    func test_confirmationResponse_afterAnotherSignIn_doesNotOverwriteCurrentUser() async throws {
        for nextUser in [makeUser(isEmailConfirmed: false), makeUser(id: UUID(), name: "Мария", isEmailConfirmed: false)] {
            let storage = makeStorage()
            let network = MockNetworkService()
            let auth = AuthService(networkService: network, keychain: MockKeychainHelper(), userDefaults: storage.defaults)
            try await auth.signIn(email: "test@test.com", password: "password")
            network.beforeConfirmationResponse = {
                network.user = nextUser
                try await auth.signIn(email: "next@test.com", password: "password")
            }

            do {
                try await auth.confirmEmail(code: "123456")
                XCTFail("A new sign-in must reject the old confirmation")
            } catch {
                guard case NetworkError.cancelled = error else { return XCTFail("Unexpected error: \(error)") }
            }

            XCTAssertEqual(currentUser(auth), nextUser)
            XCTAssertNil(storage.defaults.object(forKey: Constants.userKey))
            guard case .signedIn(let user) = auth.authState else { return XCTFail("Current session was ended") }
            XCTAssertEqual(user, nextUser)
        }
    }

    func test_oldProfileUnauthorizedResponse_doesNotEndNewSession() async throws {
        for nextUser in [makeUser(), makeUser(id: UUID(), name: "Мария")] {
            let storage = makeStorage()
            let network = MockNetworkService()
            let auth = AuthService(networkService: network, keychain: MockKeychainHelper(), userDefaults: storage.defaults)
            try await auth.signIn(email: "test@test.com", password: "password")
            network.beforeProfileResponse = {
                network.user = nextUser
                try await auth.signIn(email: "next@test.com", password: "password")
                auth.finishOnboarding()
                throw NetworkError.sessionExpired
            }

            do {
                try await auth.updateProfileInfo(ProfileInfoModel())
                XCTFail("The old request must be discarded")
            } catch {
                guard case NetworkError.cancelled = error else { return XCTFail("Unexpected error: \(error)") }
            }

            XCTAssertTrue(auth.showsMainScreen)
            XCTAssertEqual(currentUser(auth), nextUser)
            XCTAssertNil(storage.defaults.object(forKey: Constants.userKey))
            XCTAssertNil(auth.takeExpiredSessionMessage())
        }
    }

    func test_oldContentUnauthorizedResponse_doesNotEndNewSession() async throws {
        for nextUser in [makeUser(), makeUser(id: UUID(), name: "Мария")] {
            let storage = makeStorage()
            let network = MockNetworkService()
            let auth = AuthService(networkService: network, keychain: MockKeychainHelper(), userDefaults: storage.defaults)
            try await auth.signIn(email: "test@test.com", password: "password")
            let content = ContentService(networkService: network, authService: auth)
            network.beforeHistoryResponse = {
                network.user = nextUser
                try await auth.signIn(email: "next@test.com", password: "password")
                auth.finishOnboarding()
                throw NetworkError.sessionExpired
            }

            do {
                try await content.fetchHistory()
                XCTFail("The old request must be discarded")
            } catch {
                guard case NetworkError.cancelled = error else { return XCTFail("Unexpected error: \(error)") }
            }

            XCTAssertTrue(auth.showsMainScreen)
            XCTAssertEqual(currentUser(auth), nextUser)
            XCTAssertNil(storage.defaults.object(forKey: Constants.userKey))
            XCTAssertNil(auth.takeExpiredSessionMessage())
        }
    }

    func test_oldSignOutResponse_doesNotEndNewSession() async throws {
        let storage = makeStorage()
        let network = MockNetworkService()
        let auth = AuthService(networkService: network, keychain: MockKeychainHelper(), userDefaults: storage.defaults)
        try await auth.signIn(email: "test@test.com", password: "password")
        let previousSession = auth.sessionID
        network.beforeLogoutResponse = {
            try await auth.signIn(email: "test@test.com", password: "password")
        }

        do {
            try await auth.signOut()
            XCTFail("The old sign-out must be discarded")
        } catch {
            guard case NetworkError.cancelled = error else { return XCTFail("Unexpected error: \(error)") }
        }

        XCTAssertNotEqual(auth.sessionID, previousSession)
        XCTAssertEqual(currentUser(auth), network.user)
        XCTAssertNil(storage.defaults.object(forKey: Constants.userKey))
        guard case .signedIn = auth.authState else { return XCTFail("Current session was ended") }
    }

    func test_rejectedToken_endsTheLocalSessionWithoutLogout() async throws {
        let keychain = MockKeychainHelper()
        let storage = makeStorage()
        let network = MockNetworkService()
        let auth = AuthService(networkService: network, keychain: keychain, userDefaults: storage.defaults)
        try await auth.signIn(email: "test@test.com", password: "password")
        auth.finishOnboarding()
        network.errorToThrow = NetworkError.sessionExpired

        do {
            try await auth.updateProfileInfo(ProfileInfoModel())
            XCTFail("The request must fail")
        } catch NetworkError.sessionExpired {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(network.logoutCount, 0)
        XCTAssertNil(try keychain.loadAuthToken())
        XCTAssertNil(storage.defaults.object(forKey: Constants.userKey))
        XCTAssertFalse(auth.showsMainScreen)
        guard case .signedOut = auth.authState else { return XCTFail("Session was not ended") }
        XCTAssertEqual(auth.takeExpiredSessionMessage(), "Сессия истекла. Войдите снова")
    }

    func test_rejectedToken_endsTheLocalSession_whenTokenDeletionFails() async throws {
        let keychain = MockKeychainHelper()
        let storage = makeStorage()
        let network = MockNetworkService()
        let auth = AuthService(networkService: network, keychain: keychain, userDefaults: storage.defaults)
        try await auth.signIn(email: "test@test.com", password: "password")
        auth.finishOnboarding()
        keychain.deleteFails = true
        network.errorToThrow = NetworkError.sessionExpired

        do {
            try await auth.updateProfileInfo(ProfileInfoModel())
            XCTFail("The request must fail")
        } catch NetworkError.sessionExpired {
        }

        XCTAssertNil(currentUser(auth))
        XCTAssertNil(auth.sessionID)
        XCTAssertFalse(auth.showsMainScreen)
        XCTAssertEqual(auth.takeExpiredSessionMessage(), "Сессия истекла. Войдите снова")
    }

    func test_successfulAccountDeletion_endsTheLocalSession_whenTokenDeletionFails() async throws {
        let keychain = MockKeychainHelper()
        let storage = makeStorage()
        let auth = AuthService(networkService: MockNetworkService(), keychain: keychain, userDefaults: storage.defaults)
        try await auth.signIn(email: "test@test.com", password: "password")
        auth.finishOnboarding()
        keychain.deleteFails = true

        try await auth.deleteAccount()

        XCTAssertNil(currentUser(auth))
        XCTAssertNil(auth.sessionID)
        XCTAssertFalse(auth.showsMainScreen)
        XCTAssertNil(auth.takeExpiredSessionMessage())
    }

    func test_serverError_keepsTheLocalSession() async throws {
        let keychain = MockKeychainHelper()
        let storage = makeStorage()
        let network = MockNetworkService()
        let auth = AuthService(networkService: network, keychain: keychain, userDefaults: storage.defaults)
        try await auth.signIn(email: "test@test.com", password: "password")
        network.errorToThrow = NetworkError.server("Ошибка сервера")

        do {
            try await auth.updateProfileInfo(ProfileInfoModel())
            XCTFail("The request must fail")
        } catch let error as NetworkError {
            guard case .server = error else { return XCTFail("Unexpected error: \(error)") }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(try keychain.loadAuthToken(), "new-token")
        XCTAssertEqual(currentUser(auth), network.user)
        XCTAssertNil(storage.defaults.object(forKey: Constants.userKey))
        guard case .signedIn = auth.authState else { return XCTFail("A server error ended the session") }
    }

    func test_contentRequest_withRejectedToken_endsTheLocalSession() async throws {
        let keychain = MockKeychainHelper()
        let storage = makeStorage()
        let network = MockNetworkService()
        let auth = AuthService(networkService: network, keychain: keychain, userDefaults: storage.defaults)
        try await auth.signIn(email: "test@test.com", password: "password")
        auth.finishOnboarding()
        let content = ContentService(networkService: network, authService: auth)
        network.errorToThrow = NetworkError.sessionExpired

        do {
            try await content.fetchHistory()
            XCTFail("The request must fail")
        } catch NetworkError.sessionExpired {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(network.logoutCount, 0)
        XCTAssertNil(try keychain.loadAuthToken())
        XCTAssertNil(storage.defaults.object(forKey: Constants.userKey))
        XCTAssertFalse(auth.showsMainScreen)
        guard case .signedOut = auth.authState else { return XCTFail("Session was not ended") }
    }
}

private nonisolated final class UnauthorizedResponse: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        let expectedAuthorization = url.path.hasSuffix("/auth/me") ? "Bearer stale-token" : nil
        let status = request.value(forHTTPHeaderField: "Authorization") == expectedAuthorization ? 401 : 500
        guard let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(#"{"reason":"Неверная почта или пароль"}"#.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private nonisolated final class MockKeychainHelper: KeychainHelperProtocol, @unchecked Sendable {
    var data: Data?
    var saveFails = false
    var readFails = false
    var deleteFails = false

    func saveToken(_ data: Data, path: String, key: String) throws {
        if saveFails { throw KeychainError(status: errSecInteractionNotAllowed) }
        self.data = data
    }

    func getToken(path: String, key: String) throws -> Data? {
        if readFails { throw KeychainError(status: errSecInteractionNotAllowed) }
        return data
    }

    func deleteToken(path: String, key: String) throws {
        if deleteFails { throw KeychainError(status: errSecInteractionNotAllowed) }
        data = nil
    }
}

@MainActor
final class MockNetworkService: NetworkServiceProtocol {
    var user = makeUser()
    var history: [HistoryCellModel] = []
    var errorToThrow: (any Error)?
    var beforeHistoryResponse: (() async throws -> Void)?
    var beforeProfileResponse: (() async throws -> Void)?
    var beforeConfirmationResponse: (() async throws -> Void)?
    var beforeLogoutResponse: (() async throws -> Void)?
    private(set) var logoutCount = 0
    private(set) var currentUserCount = 0
    var beforeCurrentUserResponse: (() async throws -> Void)?

    func fetchCurrentUser() async throws -> UserModel {
        currentUserCount += 1
        if let errorToThrow { throw errorToThrow }
        let response = user
        try await beforeCurrentUserResponse?()
        return response
    }

    func signIn(email: String, password: String) async throws -> AuthTokenResponse {
        AuthTokenResponse(token: "new-token", user: user)
    }

    func updateProfileInfo(_ profileInfo: ProfileInfoModel) async throws -> UserModel {
        if let errorToThrow { throw errorToThrow }
        let response = user
        try await beforeProfileResponse?()
        return response
    }

    func giveAIConsent() async throws -> UserModel {
        user
    }

    func confirmEmail(code: String) async throws -> UserModel {
        let response = user
        try await beforeConfirmationResponse?()
        return response
    }

    func createAccount(name: String, email: String, password: String) async throws -> AuthTokenResponse { throw serverError }
    func ensureEmailAvailable(email: String) async throws {}
    func resetPassword(email: String, code: String, password: String) async throws -> AuthTokenResponse { throw serverError }
    func logout() async throws {
        logoutCount += 1
        try await beforeLogoutResponse?()
        throw serverError
    }
    func deleteAccount() async throws {
        if let errorToThrow { throw errorToThrow }
    }
    func requestPasswordReset(email: String) async throws { throw serverError }
    func sendEmailConfirmationCode() async throws { throw serverError }
    func fetchCurrentHoroscope() async throws -> HoroscopeModel { throw serverError }
    func fetchDailyInsight() async throws -> DailyContentModel { throw serverError }
    func fetchDailyTip() async throws -> DailyContentModel { throw serverError }
    func makePersonalityTest(selectedTests: [PersonalityTestTypes], requestID: UUID) async throws -> PersonalityResultModel { .mock }
    func makeCompatibilityTest(_ testRequest: CompatibilityTestRequest, requestID: UUID) async throws -> CompatibilityResultModel { .mock }
    func fetchHistory() async throws -> [HistoryCellModel] {
        if let errorToThrow { throw errorToThrow }
        let response = history
        try await beforeHistoryResponse?()
        return response
    }

    func fetchHistoryDetails(id: UUID) async throws -> HistoryCellModel {
        try await beforeHistoryResponse?()
        return .personalityPlaceholder
    }

    func deleteHistory(id: UUID) async throws {
        history.removeAll { $0.id == id }
    }
}
