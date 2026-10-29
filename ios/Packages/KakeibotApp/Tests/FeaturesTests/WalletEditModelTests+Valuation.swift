import Core
import Features
import Foundation
import Store
import Testing

extension WalletEditModelTests {
    @Test
    func locksInvestmentWithValuation() async throws {
        let setup = try await Setup()
        let today = LocalDate(Date(), in: .current)
        let adding = WalletEditModel(database: setup.database)
        adding.name = "積立"
        adding.kind = .investment
        let saved = try #require(await adding.save())
        try await setup.database.saveValuation(150_000, of: saved.id, on: today, at: Date())
        let model = WalletEditModel(database: setup.database, editing: saved.id)
        await model.load()

        model.kind = .bank

        #expect(model.draft.problems == [.valuedKindLocked])
    }

    @Test
    func locksKindRightAfterAddingValuation() async throws {
        let setup = try await Setup()
        let adding = WalletEditModel(database: setup.database)
        adding.name = "積立"
        adding.kind = .investment
        let saved = try #require(await adding.save())
        let model = WalletEditModel(database: setup.database, editing: saved.id)
        await model.load()

        model.pressValuation(.digit(5))
        _ = await model.saveValuation()
        let isChanged = model.isChanged
        model.kind = .bank

        #expect(!isChanged)
        #expect(!model.canSave)
        #expect(model.draft.problems == [.valuedKindLocked])
    }

    @Test
    func unlocksKindRightAfterDeletingLastValuation() async throws {
        let setup = try await Setup()
        let today = LocalDate(Date(), in: .current)
        let adding = WalletEditModel(database: setup.database)
        adding.name = "積立"
        adding.kind = .investment
        let saved = try #require(await adding.save())
        try await setup.database.saveValuation(5, of: saved.id, on: today, at: Date())
        let model = WalletEditModel(database: setup.database, editing: saved.id)
        await model.load()
        let valuation = try #require(model.valuations.first)

        _ = await model.deleteValuation(valuation.id)
        let isChanged = model.isChanged
        model.kind = .bank

        #expect(!isChanged)
        #expect(model.canSave)
    }

    @Test
    func setsInvestmentValuation() async throws {
        let setup = try await Setup()
        let adding = WalletEditModel(database: setup.database)
        adding.name = "つみたて"
        adding.kind = .investment
        adding.press(.digit(1))
        adding.press(.doubleZero)
        adding.press(.doubleZero)
        adding.press(.digit(0))
        let saved = try #require(await adding.save())

        let model = WalletEditModel(database: setup.database, editing: saved.id)
        await model.load()
        model.startValuation()
        let start = model.valuation.amount
        model.pressValuation(.clear)
        model.pressValuation(.digit(1))
        model.pressValuation(.digit(2))
        model.pressValuation(.doubleZero)
        model.pressValuation(.doubleZero)
        let isSaved = await model.saveValuation()

        let reloaded = WalletEditModel(database: setup.database, editing: saved.id)
        await reloaded.load()

        #expect(model.showsValuation)
        #expect(start == 100_000)
        #expect(isSaved)
        #expect(reloaded.balance == 120_000)
        #expect(reloaded.initialBalance == 100_000)
        #expect(reloaded.valuations.map(\.amount) == [120_000])
    }

    @Test
    func deletesValuationAndCountsFromStart() async throws {
        let setup = try await Setup()
        let adding = WalletEditModel(database: setup.database)
        adding.name = "つみたて"
        adding.kind = .investment
        adding.press(.digit(5))
        adding.press(.doubleZero)
        let saved = try #require(await adding.save())

        let model = WalletEditModel(database: setup.database, editing: saved.id)
        await model.load()
        model.startValuation()
        model.pressValuation(.digit(9))
        _ = await model.saveValuation()
        let valued = model.balance
        let id = try #require(model.valuations.first?.id)

        _ = await model.deleteValuation(id)

        #expect(valued == 9)
        #expect(model.valuations.isEmpty)
        #expect(model.balance == 500)
    }

    @Test
    func restoresDeletedValuationOnUndo() async throws {
        let setup = try await Setup()
        let adding = WalletEditModel(database: setup.database)
        adding.name = "つみたて"
        adding.kind = .investment
        adding.press(.digit(5))
        adding.press(.doubleZero)
        let saved = try #require(await adding.save())

        let model = WalletEditModel(database: setup.database, editing: saved.id)
        await model.load()
        model.startValuation()
        model.pressValuation(.digit(9))
        _ = await model.saveValuation()
        let id = try #require(model.valuations.first?.id)

        let deletion = try #require(await model.deleteValuation(id))
        await model.restore(deletion)

        #expect(model.valuations.map(\.id) == [id])
        #expect(model.balance == 9)
    }
}
