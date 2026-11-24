import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class WalletListModel {
    public let state: SettingsBoardMovingState<Wallet.ID>
    public let input: SettingsBoardSnapshotInput<EntryList>
    public let output: Output

    let dependencies: SettingsBoardDependencies

    public init(
        database: AppDatabase,
        clock: ScreenClock
    ) {
        let state = SettingsBoardMovingState<Wallet.ID>()
        let input = SettingsBoardSnapshotInput<EntryList>()

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = SettingsBoardDependencies(database: database, clock: clock)
    }
}

public extension WalletListModel {
    @MainActor
    final class Output: SettingsBoardOutput {
        let input: SettingsBoardSnapshotInput<EntryList>
        let state: SettingsBoardMovingState<Wallet.ID>

        var items: [Wallet] {
            let wallets = input.snapshot?.wallets.values ?? [:].values
            return wallets.sorted { $0.sortOrder < $1.sortOrder }
        }

        init(
            input: SettingsBoardSnapshotInput<EntryList>,
            state: SettingsBoardMovingState<Wallet.ID>
        ) {
            self.input = input
            self.state = state
        }

        public func icon(for wallet: Wallet) -> Icon? {
            input.snapshot?.icons[wallet.iconId]
        }

        public func needsHideConfirmation(of wallet: Wallet) -> Bool {
            (input.snapshot?.balance(of: wallet) ?? wallet.balance(with: [])) != 0
        }

        public func hasEntries(_ wallet: Wallet) -> Bool {
            input.snapshot.map { WalletEditModel.hasEntries(of: wallet, in: $0) } ?? false
        }

        public func balance(
            of wallet: Wallet,
            through today: LocalDate
        ) -> Int {
            input.snapshot?.balance(of: wallet, through: today) ?? wallet.balance(with: [])
        }

        public func isShared(_ wallet: Wallet) -> Bool {
            input.snapshot?.isShared(wallet) == true
        }
    }
}

extension WalletListModel: SettingsBoardDatabaseModel {
    typealias Item = Wallet

    static let loadFailedMessage = "口座を読めませんでした"

    func read() async throws -> EntryList {
        try await dependencies.database.entryList()
    }

    func updates() -> some AsyncSequence<EntryList, any Error> {
        dependencies.database.entryListUpdates()
    }
}

extension WalletListModel: SettingsBoardModel {
    public func remove(_ id: Wallet.ID) async throws -> Deletion {
        try await dependencies.database.deleteWallet(id, at: dependencies.clock.now)
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
