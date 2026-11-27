import Core
import DesignSystem
import Foundation
import Store

public extension EntryModel {
    struct WalletSection {
        public let kind: Wallet.Kind
        public let wallets: [Wallet]
    }

    enum WalletRole: Hashable, Sendable {
        case source
        case destination
    }

    struct AddedWallet: Sendable {
        public let wallet: Wallet
        public let role: WalletRole

        public init(
            wallet: Wallet,
            role: WalletRole
        ) {
            self.wallet = wallet
            self.role = role
        }
    }

    struct BillChoice: Hashable {
        public let date: LocalDate
        public let title: String
        public let period: ClosedRange<LocalDate>?
    }
}

public extension EntryModel {
    func setWallet(_ id: Wallet.ID?) {
        state.setWallet(
            id,
            offering: output.categories(for: state.type, walletId: id),
            allCategories: output.allCategories,
            allTags: output.allTags
        )
    }

    func choose(
        _ id: Wallet.ID,
        as role: WalletRole
    ) {
        switch role {
        case .source: setWallet(id)
        case .destination: state.setDestination(id)
        }
    }

    func reloadAfterSheet(
        wallets needsWallets: Bool,
        adding added: AddedWallet?
    ) async {
        await reloadCategories()
        await reloadTemplates()

        guard needsWallets else {
            return
        }

        await reloadWallets()

        if let added {
            choose(added.wallet.id, as: added.role)
            state.outcome.send(.walletChosen)
        }
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

    internal func loadHistory() async throws {
        input.history = try await dependencies.database.latestEntryList()
        updateToday()
    }

    func updateToday() {
        setToday(dependencies.clock.today)
    }

    func setToday(_ today: LocalDate) {
        if input.today != today {
            input.today = today
        }
    }

    func observeHistory() async {
        do {
            for try await list in dependencies.database.entryListUpdates() {
                guard
                    !state.closing.hasBegun,
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
