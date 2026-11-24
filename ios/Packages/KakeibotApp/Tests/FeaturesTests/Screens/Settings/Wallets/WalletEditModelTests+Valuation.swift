import Core
@testable import Features
import Foundation
import Store
import Testing

extension WalletEditModelTests {
    @Test
    func locksInvestmentWithValuation() async throws {
        let setup = try await Setup()
        let today = LocalDate(Date(), in: .current)
        let adding = WalletEditModel(database: setup.database, clock: .system)
        adding.state.name = "積立"
        adding.state.setKind(.investment)
        let saved = try #require(await adding.save())
        try await setup.database.saveValuation(150_000, of: saved.id, on: today, at: Date())
        let model = WalletEditModel(database: setup.database, clock: .system, editing: saved.id)
        await model.load()

        model.state.setKind(.bank)

        #expect(model.output.draft.problems == [.valuedKindLocked])
    }

    @Test
    func locksKindRightAfterAddingValuation() async throws {
        let setup = try await Setup()
        let adding = WalletEditModel(database: setup.database, clock: .system)
        adding.state.name = "積立"
        adding.state.setKind(.investment)
        let saved = try #require(await adding.save())
        let model = WalletEditModel(database: setup.database, clock: .system, editing: saved.id)
        await model.load()

        model.state.pressValuation(.digit(5))
        _ = await model.saveValuation()
        let isChanged = model.isChanged
        model.state.setKind(.bank)

        #expect(!isChanged)
        #expect(!model.canSave)
        #expect(model.output.draft.problems == [.valuedKindLocked])
    }

    @Test
    func unlocksKindRightAfterDeletingLastValuation() async throws {
        let setup = try await Setup()
        let today = LocalDate(Date(), in: .current)
        let adding = WalletEditModel(database: setup.database, clock: .system)
        adding.state.name = "積立"
        adding.state.setKind(.investment)
        let saved = try #require(await adding.save())
        try await setup.database.saveValuation(5, of: saved.id, on: today, at: Date())
        let model = WalletEditModel(database: setup.database, clock: .system, editing: saved.id)
        await model.load()
        let valuation = try #require(model.input.valuations.first)

        _ = await model.deleteValuation(valuation.id)
        let isChanged = model.isChanged
        model.state.setKind(.bank)

        #expect(!isChanged)
        #expect(model.canSave)
    }

    @Test
    func setsInvestmentValuation() async throws {
        let setup = try await Setup()
        let adding = WalletEditModel(database: setup.database, clock: .system)
        adding.state.name = "つみたて"
        adding.state.setKind(.investment)
        adding.state.press(.digit(1))
        adding.state.press(.doubleZero)
        adding.state.press(.doubleZero)
        adding.state.press(.digit(0))
        let saved = try #require(await adding.save())

        let model = WalletEditModel(database: setup.database, clock: .system, editing: saved.id)
        await model.load()
        model.startValuation()
        let start = model.state.valuation.amount
        model.state.pressValuation(.clear)
        model.state.pressValuation(.digit(1))
        model.state.pressValuation(.digit(2))
        model.state.pressValuation(.doubleZero)
        model.state.pressValuation(.doubleZero)
        let isSaved = await model.saveValuation()

        let reloaded = WalletEditModel(database: setup.database, clock: .system, editing: saved.id)
        await reloaded.load()

        #expect(model.output.showsValuation)
        #expect(start == 100_000)
        #expect(isSaved)
        #expect(reloaded.input.balance == 120_000)
        #expect(reloaded.output.initialBalance == 100_000)
        #expect(reloaded.input.valuations.map(\.amount) == [120_000])
    }

    @Test
    func deletesValuationAndCountsFromStart() async throws {
        let setup = try await Setup()
        let adding = WalletEditModel(database: setup.database, clock: .system)
        adding.state.name = "つみたて"
        adding.state.setKind(.investment)
        adding.state.press(.digit(5))
        adding.state.press(.doubleZero)
        let saved = try #require(await adding.save())

        let model = WalletEditModel(database: setup.database, clock: .system, editing: saved.id)
        await model.load()
        model.startValuation()
        model.state.pressValuation(.digit(9))
        _ = await model.saveValuation()
        let valued = model.input.balance
        let id = try #require(model.input.valuations.first?.id)

        _ = await model.deleteValuation(id)

        #expect(valued == 9)
        #expect(model.input.valuations.isEmpty)
        #expect(model.input.balance == 500)
    }

    @Test
    func restoresDeletedValuationOnUndo() async throws {
        let setup = try await Setup()
        let adding = WalletEditModel(database: setup.database, clock: .system)
        adding.state.name = "つみたて"
        adding.state.setKind(.investment)
        adding.state.press(.digit(5))
        adding.state.press(.doubleZero)
        let saved = try #require(await adding.save())

        let model = WalletEditModel(database: setup.database, clock: .system, editing: saved.id)
        await model.load()
        model.startValuation()
        model.state.pressValuation(.digit(9))
        _ = await model.saveValuation()
        let id = try #require(model.input.valuations.first?.id)

        let deletion = try #require(await model.deleteValuation(id))
        await model.restore(deletion)

        #expect(model.input.valuations.map(\.id) == [id])
        #expect(model.input.balance == 9)
    }

    @Test
    func offersNoUndoWhenValuationIsAlreadyGone() async throws {
        let setup = try await Setup()
        let adding = WalletEditModel(database: setup.database, clock: .system)
        adding.state.name = "つみたて"
        adding.state.setKind(.investment)
        adding.state.press(.digit(5))
        adding.state.press(.doubleZero)
        let saved = try #require(await adding.save())

        let model = WalletEditModel(database: setup.database, clock: .system, editing: saved.id)
        await model.load()
        model.startValuation()
        model.state.pressValuation(.digit(9))
        _ = await model.saveValuation()
        let id = try #require(model.input.valuations.first?.id)
        _ = try await setup.database.deleteValuation(id)

        let deletion = await model.deleteValuation(id)

        #expect(deletion == nil)
        #expect(model.state.errorNotice.message == nil)
        #expect(model.input.valuations.isEmpty)
    }
}
