import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class WalletListModel: ScreenModel {
    public private(set) var list: EntryList?
    public var movingOrder: [Wallet.ID]?

    public var errorNotice = ErrorNotice()

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension WalletListModel {
    var visible: [Wallet] {
        wallets(isHidden: false)
    }

    var hidden: [Wallet] {
        wallets(isHidden: true)
    }

    func icon(for wallet: Wallet) -> Icon? {
        list?.icons[wallet.iconId]
    }

    func balance(of wallet: Wallet) -> Int {
        let entries = list?.days.flatMap(\.entries) ?? []
        let valuations = list?.valuations ?? []

        return wallet.balance(with: entries, valuations: valuations)
    }

    func load() async {
        do {
            list = try await database.entryList()
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func observe() async {
        await observe(
            database.entryListUpdates(),
            failure: Self.loadFailedMessage
        ) { list in
            self.list = list
        }
    }
}

private extension WalletListModel {
    static let loadFailedMessage = "口座を読めませんでした"

    func wallets(isHidden: Bool) -> [Wallet] {
        let wallets = list.map { Array($0.wallets.values) } ?? []

        return wallets
            .filter { ($0.archivedAt != nil) == isHidden }
            .sorted { $0.sortOrder < $1.sortOrder }
    }
}

extension WalletListModel: SettingsBoardModel {
    public func reload() async {
        await load()
    }

    public func saveOrder(_ ids: [Wallet.ID]) async throws {
        let ids = ids + hidden.map(\.id)

        try await database.reorderWallets(ids, at: Date())
    }

    public func saveHidden(
        _ id: Wallet.ID,
        isHidden: Bool
    ) async throws {
        try await database.setWalletHidden(id, isHidden: isHidden, at: Date())
    }

    public func remove(_ id: Wallet.ID) async throws -> Deletion {
        try await database.deleteWallet(id)
    }

    public func restoreRemoved(_ deletion: Deletion) async throws {
        try await database.restore(deletion)
    }

    public func hideFailedMessage(for error: any Error) -> String? {
        guard error as? AppDatabase.WalletWriteError == .lastShownWallet else {
            return nil
        }

        return AppDatabase.WalletWriteError.lastShownMessage
    }

    public func deleteFailedMessage(for error: any Error) -> String? {
        AppDatabase.WalletWriteError.deleteMessage(for: error)
    }

    public func isInUse(_ error: any Error) -> Bool {
        error as? AppDatabase.WalletWriteError == .hasEntries
    }
}
