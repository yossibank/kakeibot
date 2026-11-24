import Core
@testable import FeatureModels
@testable import Features
import Foundation
import Store
import Testing

extension WalletEditModelTests {
    @Test
    func startsWithCashByDefault() async throws {
        let setup = try await Setup()
        let model = WalletEditModel(database: setup.database, clock: .system)

        #expect(model.state.kind == .cash)
        #expect(!model.state.isNegative)
        #expect(model.state.icon.glyph == .cash)
    }

    @Test
    func startsWithGivenKind() async throws {
        let setup = try await Setup()
        let card = WalletEditModel(database: setup.database, clock: .system, kind: .card)
        let investment = WalletEditModel(
            database: setup.database,
            clock: .system,
            kind: .investment
        )

        #expect(card.state.kind == .card)
        #expect(card.state.isNegative)
        #expect(card.state.icon.glyph == .card)
        #expect(!card.isChanged)
        #expect(investment.state.kind == .investment)
        #expect(!investment.state.isNegative)
        #expect(investment.state.icon.glyph == .invest)
    }

    @Test
    func followsKindFromGivenKind() async throws {
        let setup = try await Setup()
        let model = WalletEditModel(database: setup.database, clock: .system, kind: .card)

        model.state.setKind(.bank)
        let bank = model.state.isNegative
        let bankGlyph = model.state.icon.glyph
        model.state.setKind(.loan)

        #expect(!bank)
        #expect(bankGlyph == .bank)
        #expect(model.state.isNegative)
        #expect(model.state.icon.glyph == .contract)
    }

    @Test
    func savesGivenKindWithNegativeBalance() async throws {
        let setup = try await Setup()
        let model = WalletEditModel(database: setup.database, clock: .system, kind: .card)
        model.state.name = "楽天カード"
        model.state.press(.digit(5))
        model.state.press(.doubleZero)

        let saved = try #require(await model.save())

        #expect(saved.kind == .card)
        #expect(saved.initialBalance == -500)
    }
}
