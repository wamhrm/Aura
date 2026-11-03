//
//  NetworkServiceTests.swift
//  AuraUnitTests
//

import XCTest
@testable import Aura

nonisolated final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var statusCode = 200
    nonisolated(unsafe) static var body = Data()
    nonisolated(unsafe) static var error: URLError?
    nonisolated(unsafe) static var requests: [URLRequest] = []

    static func reset() {
        statusCode = 200
        body = Data()
        error = nil
        requests = []
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requests.append(request)

        if let error = Self.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        guard let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: Self.statusCode, httpVersion: nil, headerFields: nil) else { return }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@MainActor
final class NetworkServiceTests: XCTestCase {
    private var keychain: MockKeychain!
    private var sut: NetworkService!

    override func setUp() async throws {
        StubURLProtocol.reset()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]

        keychain = MockKeychain()
        keychain.saveAuthToken("current-token")
        sut = NetworkService(baseURL: "https://aura.test",
                             session: URLSession(configuration: configuration),
                             keychain: keychain)
    }

    // MARK: - Requests
    func test_request_usesVersionedPathAndSendsAppHeaders() async throws {
        // Given
        StubURLProtocol.body = try JSONEncoder().encode(UserModel.mock)

        // When
        _ = try await sut.fetchCurrentUser()

        // Then
        let request = try XCTUnwrap(StubURLProtocol.requests.first)
        XCTAssertEqual(request.url?.absoluteString, "https://aura.test/v1/auth/me")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer current-token")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-App-Version"), Constants.appVersion)
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Time-Zone"), TimeZone.current.identifier)
        XCTAssertNil(request.value(forHTTPHeaderField: "Idempotency-Key"))
    }

    func test_ordinaryRequest_usesShortTimeout() async throws {
        // Given
        StubURLProtocol.body = Data("[]".utf8)

        // When
        _ = try await sut.fetchHistory()

        // Then
        XCTAssertEqual(StubURLProtocol.requests.first?.timeoutInterval, 20)
    }

    func test_test_sendsItsKeyAndWaitsLongerThanTheServer() async throws {
        // Given
        let requestID = UUID()
        StubURLProtocol.body = try JSONEncoder().encode(PersonalityResultModel.mock)

        // When
        _ = try await sut.makePersonalityTest(selectedTests: [.astrology, .loveLanguage], requestID: requestID)

        // Then
        let request = try XCTUnwrap(StubURLProtocol.requests.first)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Idempotency-Key"), requestID.uuidString)
        XCTAssertEqual(request.timeoutInterval, 130)
    }

    // MARK: - Session expiry
    func test_unauthorized_reportsTheTokenOfThatRequest() async throws {
        // Given
        StubURLProtocol.statusCode = 401
        var events = sut.sessionExpiredEvents.makeAsyncIterator()

        // When
        try? await sut.logout(token: "old-token")
        let expiredToken = await events.next()

        // Then
        XCTAssertEqual(expiredToken, "old-token")
    }

    // MARK: - Errors
    func test_connectionErrors_haveTheirOwnMessages() async throws {
        // Given
        let cases: [(URLError.Code, String)] = [(.timedOut, "Сервер не ответил вовремя. Попробуйте ещё раз"),
                                                (.notConnectedToInternet, "Нет подключения к интернету"),
                                                (.secureConnectionFailed, "Не удалось связаться с сервером. Попробуйте позже")]

        for (code, expected) in cases {
            StubURLProtocol.error = URLError(code)

            // When
            let message = await errorMessage { try await self.sut.logout(token: "token") }

            // Then
            XCTAssertEqual(message, expected)
        }
    }

    // MARK: - Retries
    func test_postRequest_isNotRepeatedAfterLostConnection() async throws {
        // Given
        StubURLProtocol.error = URLError(.networkConnectionLost)

        // When
        _ = await errorMessage { try await self.sut.logout(token: "token") }

        // Then
        XCTAssertEqual(StubURLProtocol.requests.count, 1)
    }

    // MARK: - Helpers
    private func errorMessage(_ operation: () async throws -> Void) async -> String? {
        do {
            try await operation()
            XCTFail("An error was expected")
            return nil
        } catch {
            return error.userMessage
        }
    }
}
