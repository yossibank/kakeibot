import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct WalletListModelTests {
    @Test
    func reordersShownWallets() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let model = WalletListModel(database: database)
        await model.load()
        let bank = try #require(model.shown.last)

        model.move(bank.id, to: 0)
        let moving = model.shown.map(\.name)
        await model.finishMoving()
        let options = try await database.entryOptions()

        #expect(moving == ["銀行", "財布"])
        #expect(model.movingOrder == nil)
        #expect(options.wallets.map(\.name) == ["銀行", "財布"])
    }

    @Test
    func splitsHiddenWalletsAndShowsBalance() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let options = try await database.entryOptions()
        let bank = try #require(options.wallets.last)

        try await database.setWalletHidden(
            bank.id,
            isHidden: true,
            at: Date()
        )

        let model = WalletListModel(database: database)
        await model.load()
        let cash = try #require(model.shown.first)

        #expect(model.shown.map(\.name) == ["財布"])
        #expect(model.hidden.map(\.name) == ["銀行"])
        #expect(model.balance(of: cash) == 0)
    }

    @Test
    func hidesWalletButKeepsTheLastOne() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let model = WalletListModel(database: database)
        await model.load()
        let cash = try #require(model.shown.first)
        let bank = try #require(model.shown.last)

        model.move(bank.id, to: 0)
        await model.hide(bank.id)
        let shown = model.shown.map(\.name)
        let hidden = model.hidden.map(\.name)
        await model.hide(cash.id)

        #expect(shown == ["財布"])
        #expect(hidden == ["銀行"])
        #expect(model.movingOrder == nil)
        #expect(model.shown.map(\.name) == ["財布"])
        #expect(model.errorNotice.message == "最後の 1 つの口座は非表示にできません")
    }
}
