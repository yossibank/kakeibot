import Core
import Foundation
import Store

public extension WalletEditModel {
    func startValuation() {
        state.valuation = AmountCalculator(amount: max(input.balance, 0))
    }

    func saveValuation() async -> Bool {
        guard let editingId = input.editingId else {
            return false
        }

        let amount = state.valuation.amount

        do {
            try await dependencies.database.saveValuation(
                amount,
                of: editingId,
                on: dependencies.clock.today,
                at: dependencies.clock.now
            )
            await loadBalance()
            return true
        } catch {
            state.errorNotice.show(SettingsEditMessage.saveFailed, for: error)
            return false
        }
    }

    func deleteValuation(_ id: Valuation.ID) async -> Deletion? {
        do {
            let deletion = try await dependencies.database.deleteValuation(id)
            await loadBalance()
            return deletion
        } catch {
            state.errorNotice.show(SettingsEditMessage.deleteFailed, for: error)
            return nil
        }
    }

    func restore(_ deletion: Deletion) async {
        do {
            try await dependencies.database.restore(deletion)
            await loadBalance()
        } catch {
            state.errorNotice.show(Self.restoreFailedMessage, for: error)
        }
    }

    func loadBalance() async {
        guard let editingId = input.editingId else {
            return
        }

        do {
            let list = try await dependencies.database.entryList()

            guard let wallet = list.wallets[editingId] else {
                return
            }

            apply(list, to: wallet)

            try await refreshLock(of: wallet, in: list)

            input.baseline?.recordedKind = input.recordedKind
            input.baseline?.hasValuations = input.hasValuations
        } catch {
            state.errorNotice.show(Self.loadFailedMessage)
        }
    }

    func load() async {
        guard let editingId = input.editingId else {
            return
        }

        do {
            let list = try await dependencies.database.entryList()

            guard
                let wallet = list.wallets[editingId],
                let icon = list.icons[wallet.iconId]
            else {
                state.errorNotice.show(Self.loadFailedMessage)
                return
            }

            let stored = WalletDraft(wallet, icon: icon)

            state.apply(stored)
            apply(list, to: wallet)

            try await refreshLock(of: wallet, in: list)

            input.isHidden = wallet.archivedAt != nil
            input.baseline = output.draft

            await loadPayment()
        } catch {
            state.errorNotice.show(Self.loadFailedMessage)
        }
    }

    func loadPayment() async {
        guard let editingId = input.editingId else {
            return
        }

        do {
            input.payment = try await dependencies.database.recurrings().first { recurring in
                recurring.type == .transfer && recurring.toWalletId == editingId
            }
        } catch {
            state.errorNotice.show(Self.loadFailedMessage)
        }
    }

    func paymentModel(for id: Wallet.ID? = nil) -> RecurringEditModel {
        RecurringEditModel(
            parts: dependencies,
            today: dependencies.clock.today,
            editing: input.payment?.id,
            paying: id ?? input.editingId
        )
    }

    func save() async -> Wallet? {
        do {
            return try await dependencies.database.save(
                output.draft,
                editing: input.editingId,
                at: dependencies.clock.now
            )
        } catch {
            state.errorNotice.show(SettingsEditMessage.saveFailed, for: error)
            return nil
        }
    }

    func setHidden(_ isHidden: Bool) async -> Bool {
        guard let editingId = input.editingId else {
            return false
        }

        do {
            try await dependencies.database.setHidden(
                editingId,
                isHidden: isHidden,
                at: dependencies.clock.now
            )
            input.isHidden = isHidden
            return true
        } catch AppDatabase.WalletWriteError.lastShownWallet {
            state.errorNotice.show(AppDatabase.WalletWriteError.lastShownMessage)
            return false
        } catch {
            state.errorNotice.show(SettingsEditMessage.saveFailed, for: error)
            return false
        }
    }

    func delete() async -> Deletion? {
        guard let editingId = input.editingId else {
            return nil
        }

        do {
            return try await dependencies.database.deleteWallet(
                editingId,
                at: dependencies.clock.now
            )
        } catch {
            let message = AppDatabase.WalletWriteError.deleteMessage(for: error)
            state.errorNotice.show(message, for: error)
            return nil
        }
    }
}

private extension WalletEditModel {
    static let loadFailedMessage = "口座を読めませんでした"
    static let restoreFailedMessage = "元に戻せませんでした"

    static func hasRecords(
        of wallet: Wallet,
        in list: EntryList,
        recurrings: [Recurring]
    ) -> Bool {
        let hasEntries = Self.hasEntries(of: wallet, in: list)

        let hasValuations = list.valuations.contains { $0.walletId == wallet.id }

        let hasRecurrings = recurrings.contains { recurring in
            recurring.walletId == wallet.id || recurring.toWalletId == wallet.id
        }

        return hasEntries || hasValuations || hasRecurrings
    }

    func refreshLock(
        of wallet: Wallet,
        in list: EntryList
    ) async throws {
        let recurrings = try await dependencies.database.recurrings(includingHidden: true)
        let hasRecords = Self.hasRecords(of: wallet, in: list, recurrings: recurrings)
        let hasOwnValuations = list.valuations.contains { $0.walletId == wallet.id }

        let locked = output.draft.locked(
            by: wallet,
            hasRecords: hasRecords,
            hasValuations: hasOwnValuations
        )

        input.recordedKind = locked.recordedKind
        input.hasValuations = locked.hasValuations
        input.hasEntries = Self.hasEntries(of: wallet, in: list)
    }

    func apply(
        _ list: EntryList,
        to wallet: Wallet
    ) {
        input.balance = list.balance(of: wallet, through: dependencies.clock.today)
        input.totalBalance = list.balance(of: wallet)

        input.valuations = list.valuations
            .filter { $0.walletId == wallet.id }
            .sorted { $0.date > $1.date }
    }
}
