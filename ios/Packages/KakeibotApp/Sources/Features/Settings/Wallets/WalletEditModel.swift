import Core
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
    public private(set) var isHidden = false
    public private(set) var errorMessage: String?

    public let icon = IconEditModel(
        glyph: WalletEditModel.glyph(for: .cash),
        color: WalletEditModel.defaultColor
    )

    private var baseline: Snapshot?

    private let database: AppDatabase
    private let editingId: Wallet.ID?

    public init(
        database: AppDatabase,
        editing id: Wallet.ID? = nil
    ) {
        self.database = database
        self.editingId = id
    }
}

public extension WalletEditModel {
    var isEditing: Bool {
        editingId != nil
    }

    var isChanged: Bool {
        snapshot != (baseline ?? Self.blank)
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

    static func glyph(for kind: Wallet.Kind) -> Icon.Glyph {
        switch kind {
        case .cash: .cash
        case .bank: .bank
        case .card: .card
        case .emoney: .walletPass
        case .point: .coin
        case .other: .other
        }
    }

    func press(_ key: AmountCalculator.Key) {
        calculator.press(key)
    }

    func load() async {
        guard let editingId else {
            return
        }

        do {
            let list = try await database.entryList()
            let wallet = list.wallets[editingId]

            guard let wallet, let icon = list.icons[wallet.iconId] else {
                errorMessage = Self.loadFailedMessage
                return
            }

            apply(WalletDraft(wallet, icon: icon))
            isHidden = wallet.archivedAt != nil
            baseline = snapshot
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }

    func save() async -> Wallet? {
        do {
            return try await database.saveWallet(
                draft,
                editing: editingId,
                at: Date()
            )
        } catch {
            errorMessage = Self.saveFailedMessage
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
            errorMessage = Self.lastWalletMessage
            return false
        } catch {
            errorMessage = Self.saveFailedMessage
            return false
        }
    }
}

private extension WalletEditModel {
    struct Snapshot: Equatable {
        let name: String
        let kind: Wallet.Kind
        let initialBalance: Int
        let icon: IconDraft
    }

    static let defaultColor = "#C9A465"
    static let loadFailedMessage = "口座を読めませんでした"
    static let saveFailedMessage = "保存できませんでした"
    static let lastWalletMessage = "最後の 1 つの口座は非表示にできません"

    static let blank = Snapshot(
        name: "",
        kind: .cash,
        initialBalance: 0,
        icon: IconDraft(
            mark: .glyph(glyph(for: .cash)),
            color: defaultColor
        )
    )

    var snapshot: Snapshot {
        Snapshot(
            name: name,
            kind: kind,
            initialBalance: initialBalance,
            icon: icon.draft
        )
    }

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
