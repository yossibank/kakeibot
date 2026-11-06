import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class AssetsAdjustModel {
    public private(set) var calculator: AmountCalculator

    public internal(set) var errorNotice = ErrorNotice()

    public let wallet: Wallet
    public let balance: Int

    private let database: AppDatabase
    private let today: LocalDate
    private let openingAmount: Int

    public init(
        database: AppDatabase,
        wallet: Wallet,
        balance: Int,
        today: LocalDate
    ) {
        let calculator = AmountCalculator()

        self.calculator = calculator
        self.database = database
        self.wallet = wallet
        self.balance = balance
        self.today = today
        self.openingAmount = calculator.amount
    }
}

public extension AssetsAdjustModel {
    var difference: Int {
        calculator.amount - balance
    }

    var canSave: Bool {
        difference != 0
    }

    var isChanged: Bool {
        calculator.amount != openingAmount
    }

    var differenceText: String {
        guard canSave else {
            return "記録の残高と同じです"
        }

        return "差の \(AmountText.text(difference)) を「残高の調整」として今日の記録に入れます"
    }

    func press(_ key: AmountCalculator.Key) {
        calculator.press(key)
    }

    func save() async -> Bool {
        guard canSave else {
            return false
        }

        do {
            try await database.saveAdjustment(
                difference,
                of: wallet.id,
                on: today,
                at: Date()
            )

            return true
        } catch {
            errorNotice.show(Self.saveFailedMessage, for: error)
            return false
        }
    }
}

private extension AssetsAdjustModel {
    static let saveFailedMessage = "残高を合わせられませんでした"
}
