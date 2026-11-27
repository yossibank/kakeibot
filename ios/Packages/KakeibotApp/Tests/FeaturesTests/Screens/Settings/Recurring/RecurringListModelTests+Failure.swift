import Core
@testable import FeatureModels
@testable import Features
import Foundation
import Store
import Testing
import TestSupport

extension RecurringListModelTests {
    @Test
    func tellsWhenRecurringsCannotBeRead() async throws {
        let setup = try await RecordsModelTests.Setup()
        let model = RecurringListModel(parts: .system(setup.database), today: setup.today)
        try await setup.database.failReads(of: "recurring")

        await model.load()

        #expect(model.state.notices.error.message == "固定費を読めませんでした")
    }

    @Test
    func namesFailedAction() async throws {
        let setup = try await RecordsModelTests.Setup()
        let rent = try await saveRecurring("家賃", in: setup)
        _ = try await saveRecurring("ジム", in: setup)
        let model = RecurringListModel(parts: .system(setup.database), today: setup.today)

        let task = Task {
            await model.observe()
        }

        await ObservationWait.until {
            model.output.shown.count == 2
        }

        task.cancel()
        let last = try #require(model.output.shown.last)
        try await setup.database.failWrites(to: "recurring")

        await model.hide(rent.id)
        let hiding = model.state.notices.error.message
        await model.show(rent.id)
        let showing = model.state.notices.error.message
        _ = await model.delete(rent.id)
        let deleting = model.state.notices.error.message
        model.move(last.id, to: 0)
        await model.finishMoving()
        let moving = model.state.notices.error.message

        #expect(hiding == "非表示にできませんでした")
        #expect(showing == "表示に戻せませんでした")
        #expect(deleting == "削除できませんでした")
        #expect(moving == "並びを保存できませんでした")
        #expect(model.state.fields.movingOrder == nil)
    }
}

private extension RecurringListModelTests {
    func saveRecurring(
        _ memo: String,
        in setup: RecordsModelTests.Setup
    ) async throws -> Recurring {
        let options = try await setup.database.entryOptions()
        let start = try #require(LocalDate("2026-10-01"))

        let draft = RecurringDraft(
            type: .expense,
            amount: 78000,
            categoryId: options.expenseCategories[0].id,
            walletId: options.wallets[0].id,
            memo: memo,
            frequency: .monthly,
            month: 1,
            day: 27,
            startDate: start
        )

        return try await setup.database.saveRecurring(draft, today: setup.today, at: Date())
    }
}
