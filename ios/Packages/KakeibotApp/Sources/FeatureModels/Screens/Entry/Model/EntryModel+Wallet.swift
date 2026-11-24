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
        state.setWallet(
            id,
            offering: output.categories(for: state.type, walletId: id),
            allCategories: output.allCategories,
            allTags: output.allTags
        )
    }

    func newWalletModel() -> WalletEditModel {
        WalletEditModel(parts: dependencies)
    }

    func editWalletModel(_ id: Wallet.ID) -> WalletEditModel {
        WalletEditModel(parts: dependencies, editing: id)
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

            updateToday()
        } catch {
            report(error)
        }
    }

    func selectBill(_ date: LocalDate) {
        let isUsual = date == output.billChoices.first?.date
        state.payment.billMonth = isUsual ? nil : output.billRecurring?.occurrenceMonth(of: date)
    }
}

public extension EntryModel {
    internal func loadHistory() async throws {
        input.history = try await dependencies.database.latestEntryList()
        updateToday()
    }

    func updateToday() {
        let today = dependencies.clock.today

        if state.today != today {
            state.today = today
        }
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
                updateToday()
            }
        } catch {
            report(error)
        }
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
