import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class AssetsModel: ScreenModel {
    public var today: LocalDate

    public private(set) var monthStartDay: MonthStartDay = .first
    public private(set) var list: EntryList?

    public internal(set) var errorNotice = ErrorNotice()

    private var recurrings: [Recurring] = []

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

    struct UpcomingBill: Identifiable, Equatable {
        public let recurring: Recurring
        public let date: LocalDate
        public let amount: Int
        public let title: String
        public let route: String?
        public let icon: Icon?
        public let period: ClosedRange<LocalDate>?

        public var id: Recurring.ID {
            recurring.id
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

    var upcomingBills: [UpcomingBill] {
        guard let list else {
            return []
        }

        let tomorrow = today.adding(days: 1)

        return recurrings
            .filter { isCardBill($0, in: list) }
            .compactMap { recurring in
                recurring.nextDate(onOrAfter: tomorrow).map { date in
                    UpcomingBill(
                        recurring: recurring,
                        date: date,
                        amount: list.amount(of: recurring, on: date),
                        title: list.title(of: recurring) ?? Self.billTitle,
                        route: list.place(of: recurring),
                        icon: list.icon(of: recurring),
                        period: recurring.billingPeriod(paidOn: date)
                    )
                }
            }
            .sorted { $0.date < $1.date }
    }

    var upcomingBillTotal: Int {
        upcomingBills.reduce(0) { $0 + $1.amount }
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

            group.addTask {
                await self.observeRecurrings()
            }
        }
    }

    func load() async {
        do {
            list = try await database.entryList()
            recurrings = try await database.recurrings()
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }
}

private extension AssetsModel {
    static let loadFailedMessage = "残高を読めませんでした"
    static let billTitle = "引き落とし"

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
        await observe(
            database.entryListUpdates(),
            failure: Self.loadFailedMessage
        ) { list in
            self.list = list
        }
    }

    func isCardBill(
        _ recurring: Recurring,
        in list: EntryList
    ) -> Bool {
        let destination = recurring.toWalletId.flatMap { list.wallets[$0] }
        return recurring.type == .transfer && destination?.kind == .card
    }

    func observeRecurrings() async {
        await observe(
            database.recurringUpdates(),
            failure: Self.loadFailedMessage
        ) { recurrings in
            self.recurrings = recurrings
        }
    }

    func observeMonthStartDay() async {
        await observe(
            database.settingUpdates(.monthStartDay),
            failure: Self.loadFailedMessage
        ) { startDay in
            monthStartDay = startDay
        }
    }
}
