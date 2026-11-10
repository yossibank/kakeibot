import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class ReviewModel: ScreenModel {
    public var today: LocalDate {
        didSet {
            moveCache = [:]
            upcomingCache = [:]
        }
    }

    public private(set) var scale: ReviewPeriod.Scale = .month
    public private(set) var kind: ReviewKind = .expense {
        didSet {
            upcomingCache = [:]
        }
    }

    public private(set) var isListFailed = false
    public private(set) var offset = 0
    public private(set) var isMovingForward = true
    public private(set) var monthStartDay: MonthStartDay = .first
    public private(set) var weekStart: Weekday = .sunday
    public private(set) var budgets: [Budget] = []
    public private(set) var carryoverFrom: YearMonth?
    public private(set) var stampCalendar: StampCalendar?

    public private(set) var list: EntryList? {
        didSet {
            entries = list?.entries ?? []
            summaries = [:]
            moveCache = [:]
            upcomingCache = [:]
        }
    }

    public internal(set) var errorNotice = ErrorNotice()

    private(set) var entries: [Entry] = []

    private(set) var recurrings: [Recurring] = [] {
        didSet {
            moveCache = [:]
            upcomingCache = [:]
        }
    }

    @ObservationIgnored var moveCache: [ClosedRange<LocalDate>: [Move]] = [:]
    @ObservationIgnored var upcomingCache: [ClosedRange<LocalDate>: Int] = [:]

    @ObservationIgnored private var summaries: [
        ClosedRange<LocalDate>: ReviewSummary
    ] = [:]

    private let database: AppDatabase

    public init(
        database: AppDatabase,
        today: LocalDate
    ) {
        self.database = database
        self.today = today
    }
}

public extension ReviewModel {
    struct Share: Identifiable {
        public let id: AnyHashable
        public let name: String
        public let icon: Icon?
        public let amount: Int
        public let ratio: Double
        public let usage: BudgetUsage?
    }

    static let recurringShareId = AnyHashable("recurring")

    var period: ReviewPeriod {
        let current = ReviewPeriod(
            scale: scale,
            containing: today,
            monthStartDay: monthStartDay,
            weekStart: weekStart
        )

        return current.adding(offset)
    }

    var canMoveForward: Bool {
        offset < 0
    }

    var isCurrentPeriod: Bool {
        offset == 0
    }

    var summary: ReviewSummary {
        summary(in: period.range)
    }

    var previousSummary: ReviewSummary {
        summary(in: period.comparisonRange(today: today))
    }

    var isComparingPartially: Bool {
        period.range.contains(today)
    }

    var hasPreviousEntries: Bool {
        let range = period.comparisonRange(today: today)
        return entries.contains { range.contains($0.date) }
    }

    var total: Int {
        total(of: kind)
    }

    var change: Int {
        change(of: kind)
    }

    var stampTallies: [StampCalendar.Tally] {
        stampCalendar?.tallies(in: period.range) ?? []
    }

    func total(of kind: ReviewKind) -> Int {
        total(of: kind, in: summary)
    }

    func recurringId(of id: Entry.ID) -> Recurring.ID? {
        entries.first { $0.id == id }?.recurringId
    }

    func change(of kind: ReviewKind) -> Int {
        total(of: kind) - total(of: kind, in: previousSummary)
    }

    func rows(for share: Share) -> [EntryRowItem] {
        if let key = share.id.base as? MoveKey {
            return moveRows(to: key.walletId)
        }

        guard
            let list,
            let type = entryType
        else {
            return []
        }

        return entries
            .filter { entry in
                let category = entry.categoryId.map(AnyHashable.init)
                let wallet = AnyHashable(entry.walletId)

                let isRecurring = share.id == Self.recurringShareId
                    && entry.recurringId != nil

                return entry.type == type
                    && period.range.contains(entry.date)
                    && (
                        category == share.id
                            || wallet == share.id
                            || isRecurring
                    )
            }
            .sorted { $0.date > $1.date }
            .map { entry in
                EntryRowItem.dated(entry, in: list)
            }
    }

    func stampDays(of tally: StampCalendar.Tally) -> [LocalDate] {
        stampCalendar?.days(of: tally, in: period.range) ?? []
    }

    func day(on date: LocalDate) -> EntryDay? {
        list?.days.first { $0.date == date }
    }

    func run() async {
        await loadSelection()

        await withDiscardingTaskGroup { group in
            group.addTask {
                await self.observe()
            }

            group.addTask {
                await self.observeBudgets()
            }

            group.addTask {
                await self.observeStamps()
            }

            group.addTask {
                await self.observeRecurrings()
            }

            group.addTask {
                await self.observeMonthStartDay()
            }

            group.addTask {
                await self.observeCarryoverFrom()
            }

            group.addTask {
                await self.observeWeekStart()
            }
        }
    }

    func loadSelection() async {
        do {
            scale = try await database.setting(.reviewScale)
            kind = try await database.setting(.reviewKind)
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func setScale(_ scale: ReviewPeriod.Scale) {
        let scales = ReviewPeriod.Scale.allCases
        let from = scales.firstIndex(of: self.scale) ?? 0
        let to = scales.firstIndex(of: scale) ?? 0

        isMovingForward = to > from
        self.scale = scale
        offset = 0
    }

    func setKind(_ kind: ReviewKind) {
        self.kind = kind
    }

    func saveSelection() async {
        do {
            try await database.setSetting(.reviewScale, to: scale)
            try await database.setSetting(.reviewKind, to: kind)
        } catch {
            errorNotice.show(Self.saveFailedMessage, for: error)
        }
    }

    func canMove(by count: Int) -> Bool {
        offset + count <= 0
    }

    func move(by count: Int) {
        guard canMove(by: count) else {
            return
        }

        isMovingForward = count > 0
        offset += count
    }

    func moveToCurrent() {
        guard offset < 0 else {
            return
        }

        isMovingForward = true
        offset = 0
    }
}

extension ReviewModel {
    var entryType: Entry.Kind? {
        kind.entryType
    }
}

private extension ReviewModel {
    static let loadFailedMessage = "記録を読めませんでした"
    static let saveFailedMessage = "保存できませんでした"

    func summary(in range: ClosedRange<LocalDate>) -> ReviewSummary {
        if let summary = summaries[range] {
            return summary
        }

        let summary = ReviewSummary(entries: entries, in: range)

        summaries[range] = summary

        return summary
    }

    func total(
        of kind: ReviewKind,
        in summary: ReviewSummary
    ) -> Int {
        switch kind {
        case .expense: summary.expense.total
        case .income: summary.income.total
        case .balance: summary.balance
        }
    }

    func observe() async {
        isListFailed = false

        isListFailed = await observe(
            database.entryListUpdates(),
            failure: Self.loadFailedMessage
        ) { list in
            self.list = list
        }
    }

    func observeStamps() async {
        await observe(
            database.stampCalendarUpdates(),
            failure: Self.loadFailedMessage
        ) { calendar in
            stampCalendar = calendar
        }
    }

    func observeBudgets() async {
        await observe(
            database.budgetUpdates(),
            failure: Self.loadFailedMessage
        ) { budgets in
            self.budgets = budgets
        }
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

    func observeCarryoverFrom() async {
        await observe(
            database.settingUpdates(.budgetCarryoverFrom),
            failure: Self.loadFailedMessage
        ) { month in
            carryoverFrom = month
        }
    }

    func observeWeekStart() async {
        await observe(
            database.settingUpdates(.weekStart),
            failure: Self.loadFailedMessage
        ) { weekStart in
            self.weekStart = weekStart
        }
    }
}
