import Foundation

public struct WalletDraft: Hashable, Sendable {
    public var kind: Wallet.Kind
    public var name: String
    public var mark: IconDraft.Mark
    public var color: String
    public var initialBalance: Int

    public init(
        kind: Wallet.Kind,
        name: String,
        mark: IconDraft.Mark,
        color: String,
        initialBalance: Int
    ) {
        self.kind = kind
        self.name = name
        self.mark = mark
        self.color = color
        self.initialBalance = initialBalance
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

        return nameProblems + icon.problems
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
            initialBalance: wallet.initialBalance
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
        updated.updatedAt = now

        return updated
    }
}

private extension WalletDraft {
    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func validate() throws {
        if let problem = problems.first {
            throw problem
        }
    }
}
