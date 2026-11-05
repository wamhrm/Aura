//
//  ModelTests.swift
//  AuraUnitTests
//

import XCTest
@testable import Aura

@MainActor
final class ModelTests: XCTestCase {
    func test_testHost_usesAnIsolatedEnvironment() throws {
        // Given
        let serverURL = try XCTUnwrap(URL(string: Constants.baseURL))

        // When
        let testID = try XCTUnwrap(Constants.uiTestID)

        // Then
        XCTAssertEqual(serverURL.host, "127.0.0.1")
        XCTAssertEqual(Constants.localStorageDirectory.lastPathComponent, testID)
        XCTAssertTrue(Constants.tokenPath.hasSuffix(testID))
    }

    func test_birthDate_keepsTheFormatTheServerExpects() {
        // Given
        let text = "13.05.2000"

        // When
        let date = BirthDateFormatter.date(from: text)

        // Then
        XCTAssertEqual(date.map(BirthDateFormatter.dateString(from:)), text)
    }

    func test_birthTime_keepsTheFormatTheServerExpects() {
        // Given
        let text = "08:15"

        // When
        let time = BirthDateFormatter.time(from: text)

        // Then
        XCTAssertEqual(time.map(BirthDateFormatter.timeString(from:)), text)
    }

    func test_partnerRequest_trimsTheName_andSendsTimeOnlyWhenItIsKnown() {
        // Given
        var partner = PartnerInfoModel()
        partner.name = "  Анна  "

        // When
        let withoutTime = partner.compatibilityTestRequest(selectedTests: [.astrology])
        partner.knowsBirthTime = true
        let withTime = partner.compatibilityTestRequest(selectedTests: [.astrology])

        // Then
        XCTAssertEqual(withoutTime.partnerName, "Анна")
        XCTAssertNil(withoutTime.partnerBirthTime)
        XCTAssertNotNil(withTime.partnerBirthTime)
    }

    func test_historyCell_showsADateAPersonCanRead() {
        // Given
        let cell = HistoryCellModel.personalityPlaceholder

        // When
        let text = cell.dateText

        // Then
        XCTAssertTrue(text.contains("мая 2026"), text)
    }

    func test_localStorage_readsBackTheSavedUser_andStaysOutOfBackups() throws {
        // Given
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let storage = LocalStorage(baseURL: folder)

        // When
        storage.saveUser(.mock)

        // Then
        XCTAssertEqual(storage.loadUser(), .mock)
        XCTAssertEqual(try folder.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
    }

    func test_localStorage_keepsTheDataOfEachUserApart() {
        // Given
        let storage = makeStorage()
        let anna = UUID()
        let ivan = UUID()
        let insight = DailyContentModel(id: UUID(), text: "Инсайт", dateCreated: todayText())
        storage.save(insight, for: StorageKeys.dailyInsight, userId: anna)
        storage.save(insight, for: StorageKeys.dailyInsight, userId: ivan)

        // When
        storage.deleteAll(for: anna)

        // Then
        XCTAssertNil(storage.load(StorageKeys.dailyInsight, for: anna))
        XCTAssertEqual(storage.load(StorageKeys.dailyInsight, for: ivan), insight)
    }

    // MARK: - Birth date
    func test_birthDateRange_allowsOnlyAgesFrom16To100() {
        // Given
        let range = BirthDateFormatter.dateRange

        // When
        let age15 = Calendar.current.date(byAdding: .year, value: -15, to: Date()) ?? Date()
        let age17 = Calendar.current.date(byAdding: .year, value: -17, to: Date()) ?? Date()
        let age101 = Calendar.current.date(byAdding: .year, value: -101, to: Date()) ?? Date()

        // Then
        XCTAssertFalse(range.contains(age15))
        XCTAssertTrue(range.contains(age17))
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

    func test_user_savedByAnOlderAppVersion_stillLoads_withoutAccessToAI() throws {
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

    func test_cancelledRequest_isNotTreatedAsAFailure() {
        // Given
        let cancelled = NetworkError(urlError: URLError(.cancelled))
        let noConnection = NetworkError(urlError: URLError(.notConnectedToInternet))

        // When
        let results = [cancelled, noConnection].map(\.isCancellation)

        // Then
        XCTAssertEqual(results, [true, false])
    }
}
