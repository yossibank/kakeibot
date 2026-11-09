import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class WalletEditModel {
    public var name = ""
    public var isNegative = false

    public var kind: Wallet.Kind = .cash {
        didSet {
            followKind(from: oldValue)
        }
    }

    public private(set) var calculator = AmountCalculator()
    public private(set) var valuation = AmountCalculator()
    public private(set) var loanAmount = AmountCalculator()
    public private(set) var balance = 0
    public private(set) var valuations: [Valuation] = []
    public private(set) var isHidden = false
    public private(set) var payment: Recurring?
    public private(set) var recordedKind: Wallet.Kind?
    public private(set) var hasValuations = false
    public private(set) var hasEntries = false
    public private(set) var totalBalance = 0

    public internal(set) var errorNotice = ErrorNotice()

    public let icon = SettingsIconEditorModel(
        glyph: WalletEditModel.glyph(for: .cash),
        color: WalletEditModel.defaultColor
    )

    private var baseline: WalletDraft?

    private let database: AppDatabase
    private let editingId: Wallet.ID?

    public init(
        database: AppDatabase,
        editing id: Wallet.ID? = nil,
        kind: Wallet.Kind = .cash
    ) {
        self.database = database
        self.editingId = id
        self.kind = kind
        self.isNegative = kind.isDebt

        icon.glyph = Self.glyph(for: kind)

        self.baseline = draft
    }
}

public extension WalletEditModel {
    var isEditing: Bool {
        editingId != nil
    }

    var isChanged: Bool {
        baseline.map { $0 != draft } ?? false
    }

    static func glyph(for kind: Wallet.Kind) -> Icon.Glyph {
        switch kind {
        case .cash: .cash
        case .bank: .bank
        case .card: .card
        case .emoney: .walletPass
        case .point: .coin
        case .other: .other
        case .investment: .invest
        case .loan: .contract
        }
    }

    func press(_ key: AmountCalculator.Key) {
        guard
            calculator.tokens.isEmpty,
            case let .operation(operation) = key,
            operation == .add || operation == .subtract
        else {
            calculator.press(key)
            return
        }

        isNegative = operation == .subtract
    }

    func pressValuation(_ key: AmountCalculator.Key) {
        valuation.press(key)
    }

    func pressLoanAmount(_ key: AmountCalculator.Key) {
        loanAmount.press(key)
    }

    func startValuation() {
        valuation = AmountCalculator(amount: max(balance, 0))
    }

    func saveValuation() async -> Bool {
        guard let editingId else {
            return false
        }

        let amount = valuation.amount

        do {
            try await database.saveValuation(amount, of: editingId, on: Self.today, at: Date())
            await loadBalance()
            return true
        } catch {
            errorNotice.show(Self.saveFailedMessage, for: error)
            return false
        }
    }

    func deleteValuation(_ id: Valuation.ID) async -> Deletion? {
        do {
            let deletion = try await database.deleteValuation(id)
            await loadBalance()
            return deletion
        } catch {
            errorNotice.show(Self.deleteFailedMessage, for: error)
            return nil
        }
    }

    func restore(_ deletion: Deletion) async {
        do {
            try await database.restore(deletion)
            await loadBalance()
        } catch {
            errorNotice.show(Self.restoreFailedMessage, for: error)
        }
    }

    func loadBalance() async {
        guard let editingId else {
            return
        }

        do {
            let list = try await database.entryList()

            guard let wallet = list.wallets[editingId] else {
                return
            }

            apply(list, to: wallet)

            try await refreshLock(of: wallet, in: list)

            baseline?.recordedKind = recordedKind
            baseline?.hasValuations = hasValuations
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func load() async {
        guard let editingId else {
            return
        }

        do {
            let list = try await database.entryList()

            guard
                let wallet = list.wallets[editingId],
                let icon = list.icons[wallet.iconId]
            else {
                errorNotice.show(Self.loadFailedMessage)
                return
            }

            let stored = WalletDraft(wallet, icon: icon)

            apply(stored)
            apply(list, to: wallet)

            try await refreshLock(of: wallet, in: list)

            isHidden = wallet.archivedAt != nil
            baseline = draft

            await loadPayment()
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func loadPayment() async {
        guard let editingId else {
            return
        }

        do {
            payment = try await database.recurrings().first { recurring in
                recurring.type == .transfer && recurring.toWalletId == editingId
            }
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func paymentModel(for id: Wallet.ID? = nil) -> RecurringEditModel {
        let today = LocalDate(Date(), in: .current)

        return RecurringEditModel(
            database: database,
            today: today,
            editing: payment?.id,
            paying: id ?? editingId
        )
    }

    func save() async -> Wallet? {
        do {
            return try await database.saveWallet(draft, editing: editingId, at: Date())
        } catch {
            errorNotice.show(Self.saveFailedMessage, for: error)
            return nil
        }
    }

    func setHidden(_ isHidden: Bool) async -> Bool {
        guard let editingId else {
            return false
        }

        do {
            try await database.setWalletHidden(editingId, isHidden: isHidden, at: Date())
            self.isHidden = isHidden
            return true
        } catch AppDatabase.WalletWriteError.lastShownWallet {
            errorNotice.show(AppDatabase.WalletWriteError.lastShownMessage)
            return false
        } catch {
            errorNotice.show(Self.saveFailedMessage, for: error)
            return false
        }
    }

    func delete() async -> Deletion? {
        guard let editingId else {
            return nil
        }

        do {
            return try await database.deleteWallet(editingId, at: Date())
        } catch {
            let message = AppDatabase.WalletWriteError.deleteMessage(for: error)
            errorNotice.show(message, for: error)
            return nil
        }
    }
}

extension WalletEditModel {
    static func hasEntries(
        of wallet: Wallet,
        in list: EntryList
    ) -> Bool {
        list.entries.contains { entry in
            entry.walletId == wallet.id || entry.toWalletId == wallet.id
        }
    }
}

private extension WalletEditModel {
    static let defaultColor = "#C9A465"
    static let loadFailedMessage = "口座を読めませんでした"
    static let saveFailedMessage = "保存できませんでした"
    static let restoreFailedMessage = "元に戻せませんでした"
    static let deleteFailedMessage = "削除できませんでした"

    static var today: LocalDate {
        LocalDate(Date(), in: .current)
    }

    static func hasRecords(
        of wallet: Wallet,
        in list: EntryList,
        recurrings: [Recurring]
    ) -> Bool {
        let hasEntries = Self.hasEntries(of: wallet, in: list)

        let hasValuations = list.valuations.contains { $0.walletId == wallet.id }

        let hasRecurrings = recurrings.contains { recurring in
            recurring.walletId == wallet.id || recurring.toWalletId == wallet.id
        }

        return hasEntries || hasValuations || hasRecurrings
    }

    func refreshLock(
        of wallet: Wallet,
        in list: EntryList
    ) async throws {
        let recurrings = try await database.recurrings(includingHidden: true)
        let hasRecords = Self.hasRecords(of: wallet, in: list, recurrings: recurrings)
        let hasOwnValuations = list.valuations.contains { $0.walletId == wallet.id }

        let locked = draft.locked(
            by: wallet,
            hasRecords: hasRecords,
            hasValuations: hasOwnValuations
        )

        recordedKind = locked.recordedKind
        hasValuations = locked.hasValuations
        hasEntries = Self.hasEntries(of: wallet, in: list)
    }

    func followKind(from oldKind: Wallet.Kind) {
        if isNegative == oldKind.isDebt {
            isNegative = kind.isDebt
        }

        guard icon.markKind == .glyph, icon.glyph == Self.glyph(for: oldKind) else {
            return
        }

        icon.glyph = Self.glyph(for: kind)
    }

    func apply(
        _ list: EntryList,
        to wallet: Wallet
    ) {
        balance = list.balance(of: wallet, through: Self.today)
        totalBalance = list.balance(of: wallet)

        valuations = list.valuations
            .filter { $0.walletId == wallet.id }
            .sorted { $0.date > $1.date }
    }

    func apply(_ draft: WalletDraft) {
        name = draft.name
        kind = draft.kind

        icon.apply(draft.icon)

        isNegative = draft.initialBalance < 0
        calculator = AmountCalculator(amount: abs(draft.initialBalance))
        loanAmount = AmountCalculator(amount: draft.loanAmount ?? 0)
    }
}
