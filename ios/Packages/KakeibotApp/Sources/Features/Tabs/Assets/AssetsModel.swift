import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class AssetsModel {
    public var today: LocalDate

    public private(set) var list: EntryList?
    public private(set) var transferred: RecordedNotice?
    public private(set) var errorMessage: String?

    private let database: AppDatabase

    public init(
        database: AppDatabase,
        today: LocalDate
    ) {
        self.database = database
        self.today = today
    }
}

public extension AssetsModel {
    struct WalletRow: Identifiable, Equatable {
        public let wallet: Wallet
        public let icon: Icon?
        public let balance: Int

        public var id: Wallet.ID {
            wallet.id
        }
    }

    struct MonthTotal: Identifiable, Equatable {
        public let month: YearMonth
        public let total: Int

        public var id: YearMonth {
            month
        }
    }

    static let monthCount = 6

    var total: Int {
        Wallet.totalBalance(of: wallets, with: entries)
    }

    var changeFromLastMonth: Int {
        let lastMonth = today.yearMonth.adding(months: -1)
        let end = Self.lastDay(of: lastMonth)
        let previous = Wallet.totalBalance(
            of: wallets,
            with: entries,
            through: end
        )

        return total - previous
    }

    var rows: [WalletRow] {
        wallets.map { wallet in
            WalletRow(
                wallet: wallet,
                icon: list?.icons[wallet.iconId],
                balance: wallet.balance(with: entries)
            )
        }
    }

    var monthTotals: [MonthTotal] {
        (0..<Self.monthCount).reversed().map { offset in
            let month = today.yearMonth.adding(months: -offset)
            let end = offset == 0 ? today : Self.lastDay(of: month)
            let total = Wallet.totalBalance(
                of: wallets,
                with: entries,
                through: end
            )

            return MonthTotal(month: month, total: total)
        }
    }

    func showTransfer(_ entry: Entry) {
        let from = list?.wallets[entry.walletId]?.name ?? ""
        let to = entry.toWalletId.flatMap { list?.wallets[$0]?.name } ?? ""
        let amount = AmountText.text(entry.amount)

        transferred = RecordedNotice(
            entryId: entry.id,
            message: "\(from) → \(to) \(amount) を振り替えた"
        )
    }

    func undoTransfer() async {
        guard let transferred else {
            return
        }

        self.transferred = nil

        do {
            try await database.deleteEntry(transferred.entryId)
        } catch {
            errorMessage = Self.undoFailedMessage
        }
    }

    func clearTransfer() {
        transferred = nil
    }

    func load() async {
        do {
            list = try await database.entryList()
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }

    func observe() async {
        do {
            for try await list in database.entryListUpdates() {
                self.list = list
            }
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }
}

private extension AssetsModel {
    static let loadFailedMessage = "残高を読めませんでした"
    static let undoFailedMessage = "取り消せませんでした"

    static func lastDay(of month: YearMonth) -> LocalDate? {
        LocalDate(yearMonth: month, day: month.numberOfDays)
    }

    var wallets: [Wallet] {
        let wallets = list.map { Array($0.wallets.values) } ?? []

        return wallets
            .filter { $0.archivedAt == nil }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var entries: [Entry] {
        list?.days.flatMap(\.entries) ?? []
    }
}
