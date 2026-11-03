//
//  Application+BackgroundWork.swift
//  AuraBackend
//
//  Created by wamhrm on 03.11.2026.
//

import Vapor

extension Application {
    private struct MigrationsFinishedKey: StorageKey {
        typealias Value = Bool
    }

    var hasFinishedMigrations: Bool {
        get { storage[MigrationsFinishedKey.self] ?? false }
        set { storage[MigrationsFinishedKey.self] = newValue }
    }

    // The port opens right away, so a database that is slow to start can't fail the launch
    func startBackgroundWork() {
        Task {
            await runMigrations()
            await runDataCleanup()
        }
    }

    private func runMigrations() async {
        while !didShutdown {
            do {
                try await autoMigrate()
                hasFinishedMigrations = true
                return
            } catch {
                logger.error("Migrations failed, trying again in 5 seconds: \(error)")
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }

    private func runDataCleanup() async {
        let service = DataCleanupService()

        while !didShutdown {
            do {
                try await service.run(on: db)
            } catch {
                logger.error("Data cleanup failed: \(error)")
            }

            try? await Task.sleep(for: .seconds(60 * 60))
        }
    }
}
