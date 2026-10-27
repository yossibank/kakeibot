import Foundation

public struct WalletDraft: Hashable, Sendable {
    public var kind: Wallet.Kind
    public var name: String
    public var mark: IconDraft.Mark
    public var color: String
    public var initialBalance: Int
    public var loanAmount: Int?
    public var recordedKind: Wallet.Kind?

    public init(
        kind: Wallet.Kind,
        name: String,
        mark: IconDraft.Mark,
        color: String,
        initialBalance: Int,
        loanAmount: Int? = nil,
        recordedKind: Wallet.Kind? = nil
    ) {
        self.kind = kind
        self.name = name
        self.mark = mark
        self.color = color
        self.initialBalance = initialBalance
        self.loanAmount = loanAmount
        self.recordedKind = recordedKind
    }
}

public extension WalletDraft {
    var icon: IconDraft {
        IconDraft(mark: mark, color: color)
    }

    var problems: [DraftProblem] {
        let nameProblems: [DraftProblem] = trimmedName.isEmpty
            ? [.emptyName]
            : []

        let kindProblems: [DraftProblem] = isKindLocked
            ? [.kindLocked]
            : []

        return nameProblems + icon.problems + kindProblems
    }

    init(
        _ wallet: Wallet,
        icon: Icon
    ) {
        self.init(
            kind: wallet.kind,
            name: wallet.name,
            mark: IconDraft.Mark(icon),
            color: icon.color,
            initialBalance: wallet.initialBalance,
            loanAmount: wallet.loanAmount
        )
    }

    func newIcon(at now: Date) throws -> Icon {
        try validate()
        return try icon.newIcon(at: now)
    }

    func newWallet(
        iconId: Icon.ID,
        sortOrder: Int,
        at now: Date
    ) throws -> Wallet {
        try validate()

        return Wallet(
            name: trimmedName,
            kind: kind,
            iconId: iconId,
            initialBalance: initialBalance,
            loanAmount: savedLoanAmount,
            sortOrder: sortOrder,
            createdAt: now,
            updatedAt: now
        )
    }

    func applied(
        to icon: Icon,
        at now: Date
    ) throws -> Icon {
        try validate()
        return try self.icon.applied(to: icon, at: now)
    }

    func applied(
        to wallet: Wallet,
        at now: Date
    ) throws -> Wallet {
        try validate()

        var updated = wallet

        updated.name = trimmedName
        updated.kind = kind
        updated.initialBalance = initialBalance
        updated.loanAmount = savedLoanAmount
        updated.updatedAt = now

        return updated
    }
}

private extension WalletDraft {
    var isKindLocked: Bool {
        recordedKind.map { $0.isDebt != kind.isDebt } ?? false
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var savedLoanAmount: Int? {
        guard
            kind == .loan,
            let loanAmount,
            loanAmount > 0
        else {
            return nil
        }

        return loanAmount
    }

    func validate() throws {
        if let problem = problems.first {
            throw problem
        }
    }
}
