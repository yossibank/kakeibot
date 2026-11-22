import Core
import Features
import Foundation
import Store
import Testing
import TestSupport

extension AssetsModelTests {
    @Test
    func summarizesLatestTodayAfterQuickChanges() async throws {
        let setup = try await Setup()
        try await setup.save(.income, 1000, on: "2026-10-10", from: setup.cash)
        try await setup.save(.expense, 400, on: "2026-10-20", from: setup.cash)

        for _ in 1...Self.entryCount {
            try await setup.save(.income, 1, on: "2026-10-01", from: setup.cash)
        }

        let model = AssetsModel(database: setup.database, today: setup.today)
        let later = setup.today.adding(days: Self.quickChangeCount)

        let task = Task {
            await model.run()
        }

        await ObservationWait.until {
            model.list != nil
        }

        for offset in 1...Self.quickChangeCount {
            model.today = setup.today.adding(days: offset)
            await Task.yield()
        }

        await ObservationWait.until {
            model.today == later
        }

        task.cancel()

        #expect(model.plans.isEmpty)
        #expect(model.total == 600 + Self.entryCount)
        #expect(model.rows.first { $0.wallet.id == setup.cash }?.balance == 600 + Self.entryCount)
    }
}

private extension AssetsModelTests {
    static let entryCount = 500
    static let quickChangeCount = 100
}
