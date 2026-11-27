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
        let model = WalletEditModel(parts: .system(setup.database))

        #expect(model.state.kind == .cash)
        #expect(!model.state.isNegative)
        #expect(model.state.submodels.icon.state.fields.glyph == .cash)
    }

    @Test
    func startsWithGivenKind() async throws {
        let setup = try await Setup()
        let card = WalletEditModel(parts: .system(setup.database), kind: .card)
        let investment = WalletEditModel(
            parts: .system(setup.database),
            kind: .investment
        )

        #expect(card.state.kind == .card)
        #expect(card.state.isNegative)
        #expect(card.state.submodels.icon.state.fields.glyph == .card)
        #expect(!card.flow.output.isChanged)
        #expect(investment.state.kind == .investment)
        #expect(!investment.state.isNegative)
        #expect(investment.state.submodels.icon.state.fields.glyph == .invest)
    }

    @Test
    func followsKindFromGivenKind() async throws {
        let setup = try await Setup()
        let model = WalletEditModel(parts: .system(setup.database), kind: .card)

        model.state.setKind(.bank)
        let bank = model.state.isNegative
        let bankGlyph = model.state.submodels.icon.state.fields.glyph
        model.state.setKind(.loan)

        #expect(!bank)
        #expect(bankGlyph == .bank)
        #expect(model.state.isNegative)
        #expect(model.state.submodels.icon.state.fields.glyph == .contract)
    }

    @Test
    func savesGivenKindWithNegativeBalance() async throws {
        let setup = try await Setup()
        let model = WalletEditModel(parts: .system(setup.database), kind: .card)
        model.state.fields.name = "楽天カード"
        model.state.press(.digit(5))
        model.state.press(.doubleZero)

        let saved = try #require(await model.save())

        #expect(saved.kind == .card)
        #expect(saved.initialBalance == -500)
    }
}
