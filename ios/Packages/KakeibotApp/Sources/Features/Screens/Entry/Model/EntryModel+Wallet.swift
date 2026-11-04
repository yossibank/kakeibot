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

    var wallets: [Wallet] {
        let wallets = options?.wallets ?? []

        guard isEditing else {
            return wallets
        }

        let kept = [walletId, toWalletId]
            .compactMap(\.self)
            .filter { id in !wallets.contains { $0.id == id } }
            .compactMap { history?.wallets[$0] }

        return (wallets + kept).sorted { $0.sortOrder < $1.sortOrder }
    }

    var walletSections: [WalletSection] {
        Wallet.Kind.allCases.compactMap { kind in
            let wallets = wallets.filter { $0.kind == kind }

            return wallets.isEmpty
                ? nil
                : WalletSection(kind: kind, wallets: wallets)
        }
    }

    var walletName: String {
        wallet(walletId)?.name ?? walletTitle
    }

    var walletTitle: String {
        switch type {
        case .expense: "支払い元"
        case .income: "入金先"
        case .transfer: "振替元"
        }
    }

    var isUsualWallet: Bool {
        type == .transfer || walletId == wallets.first?.id
    }

    var billText: String? {
        guard
            billMonth != nil,
            let date = selectedBillDate
        else {
            return nil
        }

        return Recurring.billText(paidOn: date)
    }

    var billRecurring: Recurring? {
        guard
            type != .transfer,
            let walletId
        else {
            return nil
        }

        return cardBills.cardBill(paidBy: walletId)
    }

    var billChoices: [BillChoice] {
        guard let bill = billRecurring else {
            return []
        }

        let dates = bill.billDates(for: date, count: Recurring.billChoiceCount)

        return zip(dates, Recurring.billShiftTitles).map { date, title in
            BillChoice(
                date: date,
                title: title,
                period: bill.billingPeriod(paidOn: date)
            )
        }
    }

    var selectedBillDate: LocalDate? {
        let choices = billChoices
        let recurring = billRecurring

        let chosen = choices.first {
            recurring?.occurrenceMonth(of: $0.date) == billMonth
        }

        return chosen?.date ?? choices.first?.date
    }

    func icon(for wallet: Wallet) -> Icon? {
        options?.icons[wallet.iconId]
    }

    func wallet(_ id: Wallet.ID?) -> Wallet? {
        wallets.first { $0.id == id }
    }

    func balance(of wallet: Wallet) -> Int? {
        balances[wallet.id]
    }

    func balanceText(of wallet: Wallet) -> String? {
        guard let balance = balance(of: wallet) else {
            return nil
        }

        switch wallet.kind.role {
        case .loan: return "残り \(AmountText.text(max(-balance, 0)))"
        case .investment: return "評価額 \(AmountText.text(balance))"
        case .onHand, .card: return "残高 \(AmountText.text(balance))"
        }
    }

    func newWalletModel() -> WalletEditModel {
        WalletEditModel(database: database)
    }

    func editWalletModel(_ id: Wallet.ID) -> WalletEditModel {
        WalletEditModel(database: database, editing: id)
    }

    func reloadWallets() async {
        do {
            options = try await database.entryOptions()
            history = try await database.entryList()

            if !wallets.contains(where: { $0.id == walletId }) {
                walletId = wallets.first { $0.id != toWalletId }?.id ?? wallets.first?.id
            }

            if type == .transfer {
                if !wallets.contains(where: { $0.id == toWalletId }) {
                    toWalletId = nil
                }

                chooseDestination()
            }

            updateBalances()
        } catch {
            report(error)
        }
    }

    func selectBill(_ date: LocalDate) {
        let isUsual = date == billChoices.first?.date
        billMonth = isUsual ? nil : billRecurring?.occurrenceMonth(of: date)
    }
}

extension EntryModel {
    func loadBalances() async throws {
        history = try await database.latestEntryList()
        updateBalances()
    }

    func observeHistory() async {
        do {
            for try await list in database.entryListUpdates() {
                history = list
                updateBalances()
            }
        } catch {
            report(error)
        }
    }
}

private extension EntryModel {
    func updateBalances() {
        guard let list = history else {
            return
        }

        let entries = list.days
            .flatMap(\.entries)
            .filter { $0.id != editingId && !isOwnFee($0) }

        let valuations = list.valuations

        let pairs = wallets.map { wallet in
            let balance = wallet.balance(
                with: entries,
                valuations: valuations,
                through: Self.today
            )

            return (wallet.id, balance)
        }

        balances = Dictionary(uniqueKeysWithValues: pairs)
    }

    func isOwnFee(_ entry: Entry) -> Bool {
        guard let editingId else {
            return false
        }

        return entry.transferId == editingId
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
