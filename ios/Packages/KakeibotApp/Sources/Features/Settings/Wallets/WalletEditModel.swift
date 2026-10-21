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
    public private(set) var balance = 0
    public private(set) var isHidden = false
    public private(set) var payment: Recurring?

    public internal(set) var errorNotice = ErrorNotice()

    public let icon = IconEditModel(
        glyph: WalletEditModel.glyph(for: .cash),
        color: WalletEditModel.defaultColor
    )

    private var baseline: WalletDraft?

    private let database: AppDatabase
    private let editingId: Wallet.ID?

    public init(
        database: AppDatabase,
        editing id: Wallet.ID? = nil
    ) {
        self.database = database
        self.editingId = id
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

    var initialBalance: Int {
        isNegative ? -calculator.amount : calculator.amount
    }

    var draft: WalletDraft {
        WalletDraft(
            kind: kind,
            name: name,
            mark: icon.mark,
            color: icon.color,
            initialBalance: initialBalance
        )
    }

    var canSave: Bool {
        draft.problems.isEmpty
    }

    var saveTitle: String {
        SettingsSaveTitle.text(
            problem: draft.problems.first?.message,
            isEditing: isEditing
        )
    }

    var showsPayment: Bool {
        isEditing && (kind == .card || kind == .loan)
    }

    var showsValuation: Bool {
        isEditing && kind == .investment
    }

    var paymentTitle: String {
        kind == .loan ? "毎月の返済" : "引き落とし"
    }

    var paymentText: String {
        guard let payment else {
            return "決めていません"
        }

        let schedule = RecurringText.schedule(
            payment.frequency,
            month: payment.month ?? payment.startDate.month,
            day: payment.day
        )

        let closing = payment.closingDay.map(RecurringText.closingNote)
        let amount = payment.amount > 0 ? AmountText.text(payment.amount) : nil
        let detail = closing ?? amount
        return [schedule, detail].compactMap(\.self).joined(separator: "・")
    }

    var needsHideConfirmation: Bool {
        !isHidden && balance != 0
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
        calculator.press(key)
    }

    func pressValuation(_ key: AmountCalculator.Key) {
        valuation.press(key)
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
            try await database.saveValuation(
                amount,
                of: editingId,
                on: LocalDate(Date(), in: .current),
                at: Date()
            )

            balance = amount
            return true
        } catch {
            errorNotice.show(Self.saveFailedMessage)
            return false
        }
    }

    func load() async {
        guard let editingId else {
            return
        }

        do {
            let list = try await database.entryList()
            let wallet = list.wallets[editingId]

            guard let wallet, let icon = list.icons[wallet.iconId] else {
                errorNotice.show(Self.loadFailedMessage)
                return
            }

            apply(WalletDraft(wallet, icon: icon))
            balance = wallet.balance(
                with: list.days.flatMap(\.entries),
                valuations: list.valuations
            )
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
            return try await database.saveWallet(
                draft,
                editing: editingId,
                at: Date()
            )
        } catch {
            errorNotice.show(Self.saveFailedMessage)
            return nil
        }
    }

    func setHidden(_ isHidden: Bool) async -> Bool {
        guard let editingId else {
            return false
        }

        do {
            try await database.setWalletHidden(
                editingId,
                isHidden: isHidden,
                at: Date()
            )

            self.isHidden = isHidden
            return true
        } catch AppDatabase.WalletWriteError.lastShownWallet {
            errorNotice.show(AppDatabase.WalletWriteError.lastShownMessage)
            return false
        } catch {
            errorNotice.show(Self.saveFailedMessage)
            return false
        }
    }
}

private extension WalletEditModel {
    static let defaultColor = "#C9A465"
    static let loadFailedMessage = "口座を読めませんでした"
    static let saveFailedMessage = "保存できませんでした"

    func followKind(from oldKind: Wallet.Kind) {
        guard icon.markKind == .glyph else {
            return
        }

        guard icon.glyph == Self.glyph(for: oldKind) else {
            return
        }

        icon.glyph = Self.glyph(for: kind)
    }

    func apply(_ draft: WalletDraft) {
        name = draft.name
        kind = draft.kind
        icon.apply(draft.icon)
        isNegative = draft.initialBalance < 0
        calculator = AmountCalculator(amount: abs(draft.initialBalance))
    }
}
