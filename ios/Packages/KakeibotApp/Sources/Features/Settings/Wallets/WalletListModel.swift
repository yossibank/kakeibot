import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class WalletListModel: ScreenModel {
    public private(set) var list: EntryList?
    public private(set) var movingOrder: [Wallet.ID]?

    public internal(set) var errorNotice = ErrorNotice()

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension WalletListModel {
    var shown: [Wallet] {
        let wallets = wallets(isHidden: false)

        guard let movingOrder else {
            return wallets
        }

        return movingOrder.compactMap { id in
            wallets.first { $0.id == id }
        }
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

    func move(
        _ id: Wallet.ID,
        to index: Int
    ) {
        var order = movingOrder ?? shown.map(\.id)

        guard let from = order.firstIndex(of: id) else {
            return
        }

        let to = min(max(index, 0), order.count - 1)

        guard from != to else {
            return
        }

        order.remove(at: from)
        order.insert(id, at: to)
        movingOrder = order
    }

    func cancelMoving() {
        movingOrder = nil
    }

    @discardableResult
    func hide(_ id: Wallet.ID) async -> Bool {
        movingOrder = nil

        do {
            try await database.setWalletHidden(id, isHidden: true, at: Date())
            await load()
            return true
        } catch AppDatabase.WalletWriteError.lastShownWallet {
            errorNotice.show(AppDatabase.WalletWriteError.lastShownMessage)
            return false
        } catch {
            errorNotice.show(Self.hideFailedMessage)
            return false
        }
    }

    func delete(_ id: Wallet.ID) async -> Deletion? {
        movingOrder = nil

        do {
            let deletion = try await database.deleteWallet(id)
            await load()
            return deletion
        } catch {
            let message = AppDatabase.WalletWriteError.deleteMessage(for: error)
            errorNotice.show(message)
            return nil
        }
    }

    func restore(_ deletion: Deletion) async {
        do {
            try await database.restore(deletion)
            await load()
        } catch {
            errorNotice.show(Self.restoreFailedMessage)
        }
    }

    func deleteHidden() async -> Deletion? {
        movingOrder = nil
        let ids = hidden.map(\.id)

        let result = await SettingsBulkDelete.run(ids) { id in
            try await database.deleteWallet(id)
        } isInUse: { error in
            error as? AppDatabase.WalletWriteError == .hasEntries
        }

        await load()

        if let message = result.message {
            errorNotice.show(message)
        }

        return result.deletion
    }

    func show(_ id: Wallet.ID) async {
        do {
            try await database.setWalletHidden(id, isHidden: false, at: Date())
            await load()
        } catch {
            errorNotice.show(Self.showFailedMessage)
        }
    }

    func finishMoving() async {
        guard let movingOrder else {
            return
        }

        let ids = movingOrder + hidden.map(\.id)

        do {
            try await database.reorderWallets(ids, at: Date())
            await load()
        } catch {
            errorNotice.show(Self.saveFailedMessage)
        }

        self.movingOrder = nil
    }
}

private extension WalletListModel {
    static let loadFailedMessage = "口座を読めませんでした"
    static let saveFailedMessage = "並びを保存できませんでした"
    static let hideFailedMessage = "非表示にできませんでした"
    static let showFailedMessage = "表示に戻せませんでした"
    static let restoreFailedMessage = "元に戻せませんでした"

    func wallets(isHidden: Bool) -> [Wallet] {
        let wallets = list.map { Array($0.wallets.values) } ?? []

        return wallets
            .filter { ($0.archivedAt != nil) == isHidden }
            .sorted { $0.sortOrder < $1.sortOrder }
    }
}
