import Core
import Features
import Foundation
import Store
import Testing

extension WalletEditModelTests {
    @Test
    func startsWithCashByDefault() async throws {
        let setup = try await Setup()
        let model = WalletEditModel(database: setup.database)

        #expect(model.kind == .cash)
        #expect(!model.isNegative)
        #expect(model.icon.glyph == .cash)
    }

    @Test
    func startsWithGivenKind() async throws {
        let setup = try await Setup()
        let card = WalletEditModel(database: setup.database, kind: .card)
        let investment = WalletEditModel(database: setup.database, kind: .investment)

        #expect(card.kind == .card)
        #expect(card.isNegative)
        #expect(card.icon.glyph == .card)
        #expect(!card.isChanged)
        #expect(investment.kind == .investment)
        #expect(!investment.isNegative)
        #expect(investment.icon.glyph == .invest)
    }

    @Test
    func followsKindFromGivenKind() async throws {
        let setup = try await Setup()
        let model = WalletEditModel(database: setup.database, kind: .card)

        model.kind = .bank
        let bank = model.isNegative
        let bankGlyph = model.icon.glyph
        model.kind = .loan

        #expect(!bank)
        #expect(bankGlyph == .bank)
        #expect(model.isNegative)
        #expect(model.icon.glyph == .contract)
    }

    @Test
    func savesGivenKindWithNegativeBalance() async throws {
        let setup = try await Setup()
        let model = WalletEditModel(database: setup.database, kind: .card)
        model.name = "楽天カード"
        model.press(.digit(5))
        model.press(.doubleZero)

        let saved = try #require(await model.save())

        #expect(saved.kind == .card)
        #expect(saved.initialBalance == -500)
    }
}
