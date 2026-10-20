//
//  Application+Migrations.swift
//  AuraBackend
//
//  Created by ddorsat on 13.05.2026.
//

import Fluent
import Vapor

extension Application {
    func configureMigrations() {
        self.migrations.add(CreateUser())
        self.migrations.add(CreateToken())
        self.migrations.add(CreateUserProfileInfo())
        self.migrations.add(CreateHistory())
        self.migrations.add(CreateHoroscope())
        self.migrations.add(CreateDailyContent())
        self.migrations.add(HashTokens())
        self.migrations.add(CreateSharedHoroscopes())
        self.migrations.add(CreateIndexes())
        self.migrations.add(CreateTestUsages())
    }
}
