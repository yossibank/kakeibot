import Core
import DesignSystem
import Foundation
import Store

public extension EntryModel {
    struct WalletSection {
        public let kind: Wallet.Kind
        public let wallets: [Wallet]
    }

    struct BillChoice: Hashable {
        public let date: LocalDate
        public let title: String
        public let period: ClosedRange<LocalDate>?
    }

    func setWallet(_ id: Wallet.ID?) {
        if state.payment.setWallet(id) {
            fitCategoryToWallet()
        }
    }

    func newWalletModel() -> WalletEditModel {
        WalletEditModel(database: dependencies.database, clock: dependencies.clock)
    }

    func editWalletModel(_ id: Wallet.ID) -> WalletEditModel {
        WalletEditModel(database: dependencies.database, clock: dependencies.clock, editing: id)
    }

    func reloadWallets() async {
        do {
            input.options = try await dependencies.database.entryOptions()
            input.history = try await dependencies.database.entryList()

            let wallets = output.wallets
            let toWalletId = state.payment.toWalletId

            if !wallets.contains(where: { $0.id == state.payment.walletId }) {
                setWallet(wallets.first { $0.id != toWalletId }?.id ?? wallets.first?.id)
            }

            if state.type == .transfer {
                if !output.wallets.contains(where: { $0.id == state.payment.toWalletId }) {
                    state.setDestination(nil)
                }

                chooseDestination()
            }

            updateBalances()
        } catch {
            report(error)
        }
    }

    func selectBill(_ date: LocalDate) {
        let isUsual = date == output.billChoices.first?.date
        state.payment.billMonth = isUsual ? nil : output.billRecurring?.occurrenceMonth(of: date)
    }
}

extension EntryModel {
    func loadBalances() async throws {
        input.history = try await dependencies.database.latestEntryList()
        updateBalances()
    }

    func observeHistory() async {
        do {
            for try await list in dependencies.database.entryListUpdates() {
                guard
                    !state.isClosing,
                    list != input.history
                else {
                    continue
                }

                input.history = list
                updateBalances()
            }
        } catch {
            report(error)
        }
    }
}

private extension EntryModel {
    static func isFee(
        _ entry: Entry,
        of editingId: Entry.ID?
    ) -> Bool {
        guard let editingId else {
            return false
        }

        return entry.transferId == editingId
    }

    func updateBalances() {
        guard let list = input.history else {
            return
        }

        let editingId = input.editingId

        let entries = list.entries
            .filter { $0.id != editingId && !Self.isFee($0, of: editingId) }

        let related = Wallet.entriesByWallet(entries)
        let valuations = list.valuations
        let adjustments = list.adjustments
        let today = dependencies.clock.today

        let pairs = output.wallets.map { wallet in
            let balance = wallet.balance(
                with: related[wallet.id] ?? [],
                valuations: valuations,
                adjustments: adjustments,
                through: today
            )

            return (wallet.id, balance)
        }

        input.balances = Dictionary(uniqueKeysWithValues: pairs)
    }
}

extension EntryModel.BillChoice: Identifiable {
    public var id: LocalDate {
        date
    }
}

extension EntryModel.WalletSection: Identifiable {
    public var id: Wallet.Kind {
        kind
    }
}
