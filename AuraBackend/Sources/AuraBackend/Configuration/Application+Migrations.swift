//
//  Application+Migrations.swift
//  AuraServer
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
    }
}
