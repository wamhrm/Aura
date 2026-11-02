//
//  Application+Migrations.swift
//  AuraBackend
//
//  Created by wamhrm on 13.05.2026.
//

import Fluent
import Vapor

extension Application {
    func configureMigrations() {
        self.migrations.add(CreateSchema())
    }
}
