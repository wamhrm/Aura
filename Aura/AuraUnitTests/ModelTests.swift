//
//  ModelTests.swift
//  AuraUnitTests
//
//  Created by wamhrm on 03.11.2026.
//

import XCTest
@testable import Aura

@MainActor
final class ModelTests: XCTestCase {
    func test_userZodiacSign_followsBirthDate_atEverySignBoundary() {
        let cases: [(String, HoroscopeTypes)] = [
            ("19.01.2000", .capricorn), ("20.01.2000", .aquarius),
            ("18.02.2000", .aquarius), ("19.02.2000", .pisces),
            ("20.03.2000", .pisces), ("21.03.2000", .aries),
            ("19.04.2000", .aries), ("20.04.2000", .taurus),
            ("20.05.2000", .taurus), ("21.05.2000", .gemini),
            ("20.06.2000", .gemini), ("21.06.2000", .cancer),
            ("22.07.2000", .cancer), ("23.07.2000", .leo),
            ("22.08.2000", .leo), ("23.08.2000", .virgo),
            ("22.09.2000", .virgo), ("23.09.2000", .libra),
            ("22.10.2000", .libra), ("23.10.2000", .scorpio),
            ("21.11.2000", .scorpio), ("22.11.2000", .sagittarius),
            ("21.12.2000", .sagittarius), ("22.12.2000", .capricorn)
        ]

        for (date, sign) in cases {
            XCTAssertEqual(makeUser(dateOfBirth: date).zodiacSign, sign, date)
        }
        XCTAssertNil(makeUser(dateOfBirth: nil).zodiacSign)
    }

    func test_testHost_usesAnIsolatedEnvironment() throws {
        // Given
        let serverURL = try XCTUnwrap(URL(string: Constants.baseURL))

        // When
        let testID = try XCTUnwrap(Constants.uiTestID)

        // Then
        XCTAssertEqual(serverURL.host, "127.0.0.1")
        XCTAssertFalse(Constants.userDefaults === UserDefaults.standard)
        XCTAssertTrue(Constants.tokenPath.hasSuffix(testID))
    }

    func test_birthDate_keepsTheFormatTheServerExpects() {
        // Given
        let text = "13.05.2000"

        // When
        let date = BirthDateFormatter.date(string: text)

        // Then
        XCTAssertEqual(date.map(BirthDateFormatter.dateString(date:)), text)
    }

    func test_birthTime_keepsTheFormatTheServerExpects() {
        // Given
        let text = "08:15"

        // When
        let time = BirthDateFormatter.time(string: text)

        // Then
        XCTAssertEqual(time.map(BirthDateFormatter.timeString(date:)), text)
    }

    func test_partnerRequest_trimsTheName_andSendsTimeOnlyWhenItIsKnown() {
        // Given
        var partner = PartnerInfoModel()
        partner.name = "  анна  "

        // When
        let withoutTime = partner.compatibilityTestRequest(selectedTests: [.astrology])
        partner.knowsBirthTime = true
        let withTime = partner.compatibilityTestRequest(selectedTests: [.astrology])

        // Then
        XCTAssertEqual(withoutTime.partnerName, "Анна")
        XCTAssertNil(withoutTime.partnerBirthTime)
        XCTAssertNotNil(withTime.partnerBirthTime)
    }

    func test_keychain_readsSavedToken_andReportsMissingItem() throws {
        let keychain = KeychainHelper()
        let path = "aura-tests-" + UUID().uuidString
        defer { try? keychain.deleteToken(path: path, key: "token") }

        XCTAssertNil(try keychain.getToken(path: path, key: "token"))
        try keychain.saveToken(Data("first".utf8), path: path, key: "token")
        try keychain.saveToken(Data("second".utf8), path: path, key: "token")
        XCTAssertEqual(try keychain.getToken(path: path, key: "token"), Data("second".utf8))
        try keychain.deleteToken(path: path, key: "token")
        XCTAssertNil(try keychain.getToken(path: path, key: "token"))
        XCTAssertNoThrow(try keychain.deleteToken(path: path, key: "token"))
    }

    // MARK: - Birth date
    func test_birthDateRange_allowsOnlyAgesFrom16To100() {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        let range = BirthDateFormatter.dateRange
        let age16 = calendar.date(byAdding: .year, value: -16, to: today)!
        let age100 = calendar.date(byAdding: .year, value: -100, to: today)!
        let age100AndSixMonths = calendar.date(byAdding: .month, value: -6, to: age100)!
        let age101 = calendar.date(byAdding: .year, value: -101, to: today)!
        let age15 = calendar.date(byAdding: .day, value: 1, to: age16)!

        XCTAssertTrue(range.contains(age16))
        XCTAssertTrue(range.contains(age100))
        XCTAssertTrue(range.contains(age100AndSixMonths))
        XCTAssertFalse(range.contains(age15))
        XCTAssertFalse(range.contains(age101))
    }

    // MARK: - User
    func test_user_profileIsComplete_onlyWithBirthDateAndAllAnswers() {
        // Given
        let complete = makeUser()
        let withoutBirthDate = makeUser(dateOfBirth: nil)
        let withoutAnAnswer = makeUser(gender: nil)

        // When
        let results = [complete, withoutBirthDate, withoutAnAnswer].map(\.hasCompletedProfileInfo)

        // Then
        XCTAssertEqual(results, [true, false, false])
    }

    func test_userWithoutConsentAndConfirmationFields_hasNoAIOrConfirmedEmail() throws {
        // Given
        let json = #"{"id":"E621E1F8-C36C-495A-93FC-0C247A3E6E5F","name":"Анна"}"#

        // When
        let user = try JSONDecoder().decode(UserModel.self, from: Data(json.utf8))

        // Then
        XCTAssertEqual(user.name, "Анна")
        XCTAssertFalse(user.allowsAIAnalysis)
        XCTAssertFalse(user.hasConfirmedEmail)
    }

    // MARK: - Daily content
    func test_dailyContent_isFromToday_onlyWithTodaysDate() {
        // Given
        let today = DailyContentModel(id: UUID(), text: "Инсайт", dateCreated: todayText())
        let oldDay = DailyContentModel(id: UUID(), text: "Инсайт", dateCreated: "2000-01-01")

        // When
        let results = [today, oldDay].map(\.isFromToday)

        // Then
        XCTAssertEqual(results, [true, false])
    }

    // MARK: - Profile screen
    func test_profileDisplay_takesTheTextAndTheBarsFromTheResult() {
        // Given
        let result = PersonalityResultModel(
            name: "Анна",
            zodiacSign: .aquarius,
            selectedTests: [.behavioralPatterns],
            archetypeTitle: "Архетип",
            archetypeSubtitle: "Описание",
            overview: PersonalityOverview(title: "Обзор", description: "Текст обзора"),
            emotionalBar: [PersonalityEmotionalBar(key: .temperament, value: 7)],
            sections: [PersonalitySection(selectedTest: .behavioralPatterns,
                                          description: "Описание теста",
                                          items: [PersonalitySectionItems(key: .socialFilter, description: "Текст о фильтре")])])

        // When
        let display = ProfileDisplayModel.make(personalityResult: result, dailyTip: nil)

        // Then
        XCTAssertEqual(display.overview, "Текст обзора")
        XCTAssertEqual(display.socialFilter, "Текст о фильтре")
        XCTAssertEqual(display.temperament, 7)
        XCTAssertNil(display.thinking)
        XCTAssertTrue(display.hasTopics)
        XCTAssertFalse(display.hasBothTopics)
    }

    // MARK: - Error messages
    func test_serverError_withAReason_showsTheReason() {
        // Given
        let body = Data(#"{"reason":"Код неверный"}"#.utf8)

        // When
        let error = NetworkError(statusCode: 400, data: body)

        // Then
        XCTAssertEqual(error.userMessage, "Код неверный")
    }

    func test_serverCrash_hidesTheTechnicalReason() {
        // Given
        let body = Data(#"{"reason":"database is down"}"#.utf8)

        // When
        let error = NetworkError(statusCode: 500, data: body)

        // Then
        XCTAssertEqual(error.userMessage, "Сервис временно недоступен. Попробуйте позже")
    }

    func test_serverLimit_withAReason_isRecognizedAsALimit() {
        // Given
        let body = Data(#"{"reason":"Код уже отправлен"}"#.utf8)

        // When
        let error = NetworkError(statusCode: 429, data: body)

        // Then
        guard case .limited(let message) = error else { return XCTFail("expected a limit, got \(error)") }
        XCTAssertEqual(message, "Код уже отправлен")
    }

    func test_emailCodeRateLimits_areDistinguishedByCode() {
        let body = Data(#"{"reason":"Too many requests"}"#.utf8)
        let recent = NetworkError(statusCode: 429, data: body, code: "email_code_recently_requested")
        let daily = NetworkError(statusCode: 429, data: body, code: "email_code_daily_limit")

        guard case .emailCodeRecentlyRequested = recent else { return XCTFail("Expected the resend interval") }
        guard case .emailCodeDailyLimit = daily else { return XCTFail("Expected the daily limit") }
    }

    func test_serverError_withoutAReason_dependsOnTheStatus() {
        // Given
        let statuses = [401, 404, 409, 429]

        // When
        let messages = statuses.map { NetworkError(statusCode: $0, data: Data()).userMessage }

        // Then
        XCTAssertEqual(messages, ["Неправильная почта или пароль",
                                  "Данные не найдены",
                                  "Пользователь уже зарегистрирован",
                                  "Слишком много запросов. Попробуйте позже"])
    }

    func test_connectionError_showsAClearMessage() {
        // Given
        let codes: [URLError.Code] = [.notConnectedToInternet, .timedOut, .cannotFindHost]

        // When
        let messages = codes.map { NetworkError(urlError: URLError($0)).userMessage }

        // Then
        XCTAssertEqual(messages, ["Нет подключения к интернету",
                                  "Сервер не ответил вовремя. Попробуйте ещё раз",
                                  "Не удалось связаться с сервером. Попробуйте позже"])
    }
}
