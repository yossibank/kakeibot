import Core
import DesignSystem
import Features
import Foundation
import Store
import Testing

extension RecordsModelTests {
    @Test
    func showsAdjustmentOnItsDayWithoutTotals() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12")
        try await setup.adjust(-500, on: "2026-10-14")
        let model = RecordsModel(database: setup.database, today: setup.today)

        await model.load()
        let date = try #require(LocalDate("2026-10-14"))
        let rows = model.adjustmentRows(on: date)

        #expect(model.days.map(\.date.description) == ["2026-10-14", "2026-10-12"])
        #expect(model.expenseTotal == 980)
        #expect(model.day(on: date)?.entries.isEmpty == true)
        #expect(rows.map { AmountText.text($0.adjustment.amount, sign: .plus) } == ["−¥500"])
        #expect(rows.map(\.walletName) == ["財布"])
    }

    @Test
    func hidesAdjustmentsWhileFiltering() async throws {
        let setup = try await Setup()
        try await setup.adjust(700, on: "2026-10-14")
        let options = try await setup.database.entryOptions()
        let model = RecordsModel(database: setup.database, today: setup.today)

        await model.load()
        model.filter.walletIds = [options.wallets[0].id]
        let date = try #require(LocalDate("2026-10-14"))

        #expect(model.days.isEmpty)
        #expect(model.adjustmentRows(on: date).isEmpty)
    }

    @Test
    func deletesAdjustmentWithUndo() async throws {
        let setup = try await Setup()
        try await setup.adjust(700, on: "2026-10-14")
        let model = RecordsModel(database: setup.database, today: setup.today)
        await model.load()
        let date = try #require(LocalDate("2026-10-14"))
        let row = try #require(model.adjustmentRows(on: date).first)

        let deletion = try #require(await model.deleteAdjustment(row.id))
        let deleted = try await setup.database.entryList().adjustments
        try await setup.database.restore(deletion)
        let restored = try await setup.database.entryList().adjustments

        #expect(AmountText.text(row.adjustment.amount, sign: .plus) == "+¥700")
        #expect(deleted.isEmpty)
        #expect(restored.map(\.id) == [row.id])
    }
}

extension RecordsModelTests.Setup {
    func adjust(
        _ amount: Int,
        on text: String
    ) async throws {
        let options = try await database.entryOptions()
        let wallet = try #require(options.wallets.first)
        let date = try #require(LocalDate(text))

        try await database.saveAdjustment(amount, of: wallet.id, on: date, at: Date())
    }
}
