import Core
import Store

public extension AssetsModel {
    @MainActor
    final class Output {
        let input: Input
        let state: State

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }
    }
}

public extension AssetsModel.Output {
    var today: LocalDate {
        input.summary.input.today
    }

    var list: EntryList? {
        input.summary.input.list
    }

    var monthStartDay: MonthStartDay {
        input.summary.input.monthStartDay
    }

    var holdings: Holdings {
        input.summary.holdings
    }

    var outlook: AssetsModel.Outlook {
        input.summary.outlook
    }

    var changeFromLastMonth: Int {
        input.summary.changeFromLastMonth
    }

    var rows: [AssetsModel.WalletRow] {
        input.summary.rows
    }

    var sections: [AssetsModel.WalletSection] {
        input.summary.sections
    }

    var ownedSections: [AssetsModel.WalletSection] {
        sections.owned
    }

    var owedSections: [AssetsModel.WalletSection] {
        sections.owed
    }

    var upcomingBills: [AssetsModel.UpcomingBill] {
        input.summary.upcomingBills
    }

    var billPages: [BillPage] {
        input.summary.billPages
    }

    var monthTotals: [AssetsModel.MonthTotal] {
        input.summary.monthTotals
    }

    var plans: [AssetsModel.Plan] {
        input.summary.plans
    }

    var currentMonth: YearMonth {
        today.periodMonth(startingOn: monthStartDay)
    }

    var total: Int {
        holdings.available
    }

    var showsNetWorth: Bool {
        input.summary.wallets.contains { [.investment, .loan].contains($0.kind.role) }
    }

    var shownBillPage: BillPage? {
        BillPage.page(state.fields.billPage, in: billPages)
    }

    var shownUpcomingBills: [AssetsModel.UpcomingBill] {
        shownBillPage.map { upcomingBills(in: $0.month) } ?? []
    }

    var upcomingBillTotal: Int {
        shownBillPage?.total ?? 0
    }

    func upcomingBills(in month: YearMonth) -> [AssetsModel.UpcomingBill] {
        upcomingBills.filter { $0.bill.month == month }
    }
}
