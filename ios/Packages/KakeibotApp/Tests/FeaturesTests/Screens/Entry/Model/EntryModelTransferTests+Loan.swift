import Core
import FeatureModels
import Features
import Foundation
import Store
import Testing

extension EntryModelTransferTests {
    @Test
    func capsLoanPayoffAtLargestAmount() async throws {
        let setup = try await Setup()

        let wallet = WalletDraft(
            kind: .loan,
            name: "住宅ローン",
            mark: .glyph(.contract),
            color: "#4A6FA5",
            initialBalance: -AmountCalculator.maxValue
        )

        let loan = try await setup.database.save(wallet, at: Date())
        try await setup.saveTransfer(1000, from: loan.id, to: setup.bank, at: 1)
        let model = EntryModel(
            parts: .system(setup.database),
            date: setup.date,
            type: .transfer
        )

        await model.load()
        model.setWallet(setup.bank)
        model.state.setDestination(loan.id)
        model.payOffLoan()

        #expect(model.output.loanRemaining == AmountCalculator.maxValue + 1000)
        #expect(model.output.amount == AmountCalculator.maxValue)
    }
}
