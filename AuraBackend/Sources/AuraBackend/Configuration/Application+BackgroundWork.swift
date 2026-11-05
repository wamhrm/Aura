//
//  Application+BackgroundWork.swift
//  AuraBackend
//
//  Created by wamhrm on 03.11.2026.
//

import Vapor

extension Application {
    func startDataCleanup() -> Task<Void, Never> {
        Task {
            let service = DataCleanupService()

            while !Task.isCancelled {
                do {
                    try await service.run(database: db)
                } catch {
                    if Task.isCancelled { return }
                    logger.error("Data cleanup failed: \(error)")
                }

                do {
                    try await Task.sleep(for: .seconds(60 * 60))
                } catch {
                    return
                }
            }
        }
    }
}
