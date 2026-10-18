import Core
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class AssetsModel {
    public var today: LocalDate

    public private(set) var monthStartDay: MonthStartDay = .first
    public private(set) var list: EntryList?
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

    var currentMonth: YearMonth {
        today.periodMonth(startingOn: monthStartDay)
    }

    var total: Int {
        Wallet.totalBalance(of: wallets, with: entries)
    }

    var changeFromLastMonth: Int {
        let lastMonth = currentMonth.adding(months: -1)
        let end = lastMonth.period(startingOn: monthStartDay).upperBound
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
            let month = currentMonth.adding(months: -offset)
            let period = month.period(startingOn: monthStartDay)
            let end = offset == 0 ? today : period.upperBound
            let total = Wallet.totalBalance(
                of: wallets,
                with: entries,
                through: end
            )

            return MonthTotal(month: month, total: total)
        }
    }

    func run() async {
        await withDiscardingTaskGroup { group in
            group.addTask {
                await self.observe()
            }

            group.addTask {
                await self.observeMonthStartDay()
            }
        }
    }

    func load() async {
        do {
            list = try await database.entryList()
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }
}

private extension AssetsModel {
    static let loadFailedMessage = "残高を読めませんでした"

    var wallets: [Wallet] {
        let wallets = list.map { Array($0.wallets.values) } ?? []

        return wallets
            .filter { $0.archivedAt == nil }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var entries: [Entry] {
        list?.days.flatMap(\.entries) ?? []
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

    func observeMonthStartDay() async {
        do {
            for try await startDay in database.settingUpdates(.monthStartDay) {
                monthStartDay = startDay
            }
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }
}
