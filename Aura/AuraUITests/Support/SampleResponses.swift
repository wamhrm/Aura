//
//  SampleResponses.swift
//  AuraUITests
//

import Foundation
import XCTest

// What the server answers in flow tests
enum SampleResponses {
    static let auth = Data(#"""
        {
          "token": "c2FtcGxlLXRva2Vu",
          "user": {
            "id": "6F9619FF-8B86-4D01-B42D-00CF4FC964FF",
            "name": "Анна",
            "email": "anna@example.test",
            "dateOfBirth": "13.05.2000",
            "birthTime": "08:15",
            "gender": "woman",
            "socialType": "extrovert",
            "conflictStyle": "direct",
            "emotionalCore": "intuitive",
            "decisionStyle": "spontaneous",
            "coreFocus": "growth",
            "hasAIConsent": true,
            "isEmailConfirmed": true
          }
        }
        """#.utf8)

    static let horoscope = Data(#"""
        {
          "id": "1B4E28BA-2FA1-11D2-883F-0016D3CCA427",
          "type": "taurus",
          "dateStart": "2 нояб.",
          "dateEnd": "8 нояб.",
          "description": "Краткий гороскоп на неделю",
          "items": [
            { "key": "love", "description": "Прогноз по любви" },
            { "key": "health", "description": "Прогноз по здоровью" },
            { "key": "work", "description": "Прогноз по работе" }
          ]
        }
        """#.utf8)

    static let personalityResult = Data(#"""
        {
          "name": "Анна",
          "zodiacSign": "taurus",
          "selectedTests": ["astrology", "behavioralPatterns"],
          "archetypeTitle": "Тихий стратег",
          "archetypeSubtitle": "Вы думаете дольше других и редко ошибаетесь",
          "overview": {
            "title": "Основная характеристика",
            "description": "Общий персональный вывод"
          },
          "emotionalBar": [
            { "key": "temperament", "value": 3 },
            { "key": "thinking", "value": 8 },
            { "key": "organization", "value": 7 },
            { "key": "relationships", "value": 5 }
          ],
          "sections": [
            {
              "selectedTest": "astrology",
              "description": "Основной текст секции",
              "items": [
                { "key": "natalChart", "description": "Описание пункта" },
                { "key": "planetaryAspects", "description": "Описание пункта" }
              ]
            },
            {
              "selectedTest": "behavioralPatterns",
              "description": "Основной текст секции",
              "items": [
                { "key": "socialFilter", "description": "Описание пункта" },
                { "key": "energyDrain", "description": "Описание пункта" }
              ]
            }
          ]
        }
        """#.utf8)

    static let compatibilityResult = Data(#"""
        {
          "userName": "Анна",
          "userZodiacSign": "taurus",
          "partnerName": "Иван",
          "partnerZodiacSign": "aquarius",
          "compatibilityScore": 64,
          "selectedTests": ["astrology", "behavioralPatterns", "attachmentCompatibility"],
          "title": "Спокойный союз",
          "subtitle": "Вы сближаетесь медленно, но надолго",
          "overview": {
            "title": "Основная динамика",
            "description": "Общий вывод о паре"
          },
          "emotionalBar": [
            { "key": "emotionalResonance", "value": 6 },
            { "key": "innerOpenness", "value": 4 },
            { "key": "soulAlignment", "value": 7 },
            { "key": "emotionalWarmth", "value": 5 }
          ],
          "sections": [
            {
              "selectedTest": "astrology",
              "description": "Основной текст секции",
              "items": [
                { "key": "synastry", "description": "Описание пункта" },
                { "key": "karmicLesson", "description": "Описание пункта" }
              ]
            },
            {
              "selectedTest": "behavioralPatterns",
              "description": "Основной текст секции",
              "items": [
                { "key": "dominanceDynamics", "description": "Описание пункта" },
                { "key": "emotionalResonance", "description": "Описание пункта" }
              ]
            },
            {
              "selectedTest": "attachmentCompatibility",
              "description": "Основной текст секции",
              "items": [
                { "key": "attachmentBond", "description": "Описание пункта" },
                { "key": "comfortDistance", "description": "Описание пункта" }
              ]
            }
          ],
          "forecast": {
            "recognitionTitle": "Редкое узнавание",
            "recognitionDescription": "Описание",
            "potentialTitle": "Стабильный союз",
            "potentialDescription": "Описание"
          }
        }
        """#.utf8)

    static let historyList = Data(#"""
        [
          {
            "id": "7C9E6679-7425-40DE-944B-E07FC1F90AE7",
            "kind": "compatibility",
            "createdAt": "2026-11-03T09:30:00Z",
            "selectedTests": ["astrology", "behavioralPatterns", "attachmentCompatibility"],
            "archetypeTitle": "Спокойный союз",
            "archetypeSubtitle": "Вы сближаетесь медленно, но надолго",
            "zodiacSign": "taurus",
            "compatibilityScore": 64,
            "partnerName": "Иван",
            "partnerZodiacSign": "aquarius"
          },
          {
            "id": "16FD2706-8BAF-433B-82EB-8C7FADA847DA",
            "kind": "personality",
            "createdAt": "2026-11-03T09:00:00Z",
            "selectedTests": ["astrology", "behavioralPatterns"],
            "archetypeTitle": "Тихий стратег",
            "archetypeSubtitle": "Вы думаете дольше других и редко ошибаетесь",
            "zodiacSign": "taurus"
          }
        ]
        """#.utf8)

    static let daily = Data(#"""
        {
          "id": "9B2C7D10-5E3F-4A61-8C47-2F1D6E0A9B35",
          "text": "Сегодня вы спокойнее, чем кажется",
          "dateCreated": "2026-11-03"
        }
        """#.utf8)

    static func object(_ data: Data) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}
