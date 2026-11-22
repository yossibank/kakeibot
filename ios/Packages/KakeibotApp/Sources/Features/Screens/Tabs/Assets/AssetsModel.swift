import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class AssetsModel: ScreenModel {
    public var billPage = 0

    public private(set) var isListFailed = false
    public private(set) var rewardBank: RewardBank?

    public internal(set) var errorNotice = ErrorNotice()

    let database: AppDatabase

    private var summary: AssetsSummary

    @ObservationIgnored private var latestInput: AssetsSummary.Input
    @ObservationIgnored private var refreshCount = 0

    public init(
        database: AppDatabase,
        today: LocalDate
    ) {
        let input = AssetsSummary.Input(today: today)

        self.database = database
        self.latestInput = input
        self.summary = AssetsSummary(input)
    }
}

public extension AssetsModel {
    static let monthCount = AssetsSummary.Input.monthCount

    var today: LocalDate {
        get {
            summary.input.today
        }
        set {
            latestInput.today = newValue
            refreshLater()
        }
    }

    var list: EntryList? {
        summary.input.list
    }

    var monthStartDay: MonthStartDay {
        summary.input.monthStartDay
    }

    var holdings: Holdings {
        summary.holdings
    }

    var outlook: Outlook {
        summary.outlook
    }

    var changeFromLastMonth: Int {
        summary.changeFromLastMonth
    }

    var rows: [WalletRow] {
        summary.rows
    }

    var sections: [WalletSection] {
        summary.sections
    }

    var upcomingBills: [UpcomingBill] {
        summary.upcomingBills
    }

    var billPages: [BillPage] {
        summary.billPages
    }

    var monthTotals: [MonthTotal] {
        summary.monthTotals
    }

    var plans: [Plan] {
        summary.plans
    }

    var currentMonth: YearMonth {
        today.periodMonth(startingOn: monthStartDay)
    }

    var total: Int {
        holdings.available
    }

    var showsNetWorth: Bool {
        summary.wallets.contains { [.investment, .loan].contains($0.kind.role) }
    }

    var shownBillPage: BillPage? {
        BillPage.page(billPage, in: billPages)
    }

    var shownUpcomingBills: [UpcomingBill] {
        shownBillPage.map { upcomingBills(in: $0.month) } ?? []
    }

    var upcomingBillTotal: Int {
        shownBillPage?.total ?? 0
    }

    func upcomingBills(in month: YearMonth) -> [UpcomingBill] {
        upcomingBills.filter { $0.bill.month == month }
    }

    func adjustModel(for row: WalletRow) -> AssetsAdjustModel {
        AssetsAdjustModel(
            database: database,
            wallet: row.wallet,
            balance: row.balance,
            today: today
        )
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

            group.addTask {
                await self.observeRewardBank()
            }
        }
    }

    func load() async {
        do {
            latestInput.list = try await database.entryList()
            latestInput.recurrings = try await database.recurrings()
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }

        await refresh()
    }
}

private extension AssetsModel {
    static let loadFailedMessage = "残高を読めませんでした"

    func refreshLater() {
        Task {
            await refresh()
        }
    }

    func refresh() async {
        refreshCount += 1

        let count = refreshCount
        let summary = await AssetsSummary.make(latestInput)

        guard count == refreshCount else {
            return
        }

        self.summary = summary
        billPage = min(billPage, max(summary.billPages.count - 1, 0))
    }

    func observe() async {
        isListFailed = false

        isListFailed = await observe(
            database.entryListUpdates(),
            failure: Self.loadFailedMessage
        ) { list in
            latestInput.list = list
            refreshLater()
        }
    }

    func observeRewardBank() async {
        await observe(
            database.rewardBankUpdates(),
            failure: Self.loadFailedMessage
        ) { bank in
            rewardBank = bank
        }
    }

    func observeRecurrings() async {
        await observe(
            database.recurringUpdates(),
            failure: Self.loadFailedMessage
        ) { recurrings in
            latestInput.recurrings = recurrings
            refreshLater()
        }
    }

    func observeMonthStartDay() async {
        await observe(
            database.settingUpdates(.monthStartDay),
            failure: Self.loadFailedMessage
        ) { startDay in
            latestInput.monthStartDay = startDay
            refreshLater()
        }
    }
}
