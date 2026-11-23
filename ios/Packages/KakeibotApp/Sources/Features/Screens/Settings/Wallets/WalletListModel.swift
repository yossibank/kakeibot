import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class WalletListModel {
    public var movingOrder: [Wallet.ID]?
    public var errorNotice = ErrorNotice()

    public internal(set) var snapshot: EntryList?

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension WalletListModel {
    func icon(for wallet: Wallet) -> Icon? {
        snapshot?.icons[wallet.iconId]
    }

    func needsHideConfirmation(of wallet: Wallet) -> Bool {
        (snapshot?.balance(of: wallet) ?? wallet.balance(with: [])) != 0
    }

    func hasEntries(_ wallet: Wallet) -> Bool {
        snapshot.map { WalletEditModel.hasEntries(of: wallet, in: $0) } ?? false
    }

    func balance(of wallet: Wallet) -> Int {
        snapshot?.balance(of: wallet, through: Self.today) ?? wallet.balance(with: [])
    }

    func isShared(_ wallet: Wallet) -> Bool {
        snapshot?.isShared(wallet) == true
    }
}

extension WalletListModel: SettingsBoardDatabaseModel {
    typealias Item = Wallet

    static let loadFailedMessage = "口座を読めませんでした"

    func read() async throws -> EntryList {
        try await database.entryList()
    }

    func updates() -> some AsyncSequence<EntryList, any Error> {
        database.entryListUpdates()
    }

    func items(in snapshot: EntryList) -> [Wallet] {
        snapshot.wallets.values.sorted { $0.sortOrder < $1.sortOrder }
    }

    func isHidden(_ item: Wallet) -> Bool {
        item.archivedAt != nil
    }
}

private extension WalletListModel {
    static var today: LocalDate {
        LocalDate(Date(), in: .current)
    }
}

extension WalletListModel: SettingsBoardModel {
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
        try await database.deleteWallet(id, at: Date())
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
