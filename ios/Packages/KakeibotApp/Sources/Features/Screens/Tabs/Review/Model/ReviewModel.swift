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
            cache.invalidate(.today)
        }
    }

    public private(set) var scale: ReviewPeriod.Scale = .month
    public private(set) var kind: ReviewKind = .expense {
        didSet {
            cache.invalidate(.kind)
        }
    }

    public private(set) var isListFailed = false
    public private(set) var offset = 0
    public private(set) var isMovingForward = true
    public private(set) var monthStartDay: MonthStartDay = .first
    public private(set) var weekStart: Weekday = .sunday
    public private(set) var budgets: [Budget] = []
    public private(set) var carryoverFrom: YearMonth?
    public private(set) var stampBook: StampBook?

    public private(set) var list: EntryList? {
        didSet {
            entries = list?.entries ?? []
            cache.invalidate(.list)
        }
    }

    public internal(set) var errorNotice = ErrorNotice()
    public internal(set) var showsStoreReviewCard = false

    public internal(set) var goals: [ReviewGoal] = []
    public internal(set) var newReportKey: String?

    var reasons: [String: String] = [:]
    var notes: [String: String] = [:]

    private(set) var entries: [Entry] = []

    private(set) var noSpendDays: Set<LocalDate> = [] {
        didSet {
            cache.invalidate(.noSpendDays)
        }
    }

    private(set) var recurrings: [Recurring] = [] {
        didSet {
            cache.invalidate(.recurrings)
        }
    }

    @ObservationIgnored var cache = Cache()
    @ObservationIgnored var reasonRequests: Set<String> = []
    @ObservationIgnored var noteRequests: Set<String> = []

    let database: AppDatabase

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

    var stampTallies: [StampBook.Tally] {
        stampBook?.tallies(in: period.range) ?? []
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

        if let key = share.id.base as? FactorKey {
            return factorRows(of: key)
        }

        if let key = share.id.base as? MonthKey {
            return monthRows(of: key)
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

    func stampDays(of tally: StampBook.Tally) -> [LocalDate] {
        stampBook?.days(of: tally, in: period.range) ?? []
    }

    func day(on date: LocalDate) -> EntryDay? {
        list?.days.first { $0.date == date }
    }

    func run() async {
        await loadSelection()

        await observeAll([
            {
                await self.observe(
                    self.database.entryListUpdates(),
                    into: \.list,
                    failing: \.isListFailed
                )
            },
            {
                await self.observe(self.database.budgetUpdates(), into: \.budgets)
            },
            {
                await self.observe(self.database.stampBookUpdates(), into: \.stampBook)
            },
            {
                await self.observe(self.database.noSpendDayUpdates(), into: \.noSpendDays)
            },
            {
                await self.observe(self.database.recurringUpdates(), into: \.recurrings)
            },
            {
                await self.observe(
                    self.database.settingUpdates(.monthStartDay),
                    into: \.monthStartDay
                )
            },
            {
                await self.observe(
                    self.database.settingUpdates(.budgetCarryoverFrom),
                    into: \.carryoverFrom
                )
            },
            {
                await self.observe(self.database.settingUpdates(.weekStart), into: \.weekStart)
            }
        ])
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

extension ReviewModel {
    static let loadFailedMessage = "記録を読めませんでした"
}

private extension ReviewModel {
    static let saveFailedMessage = "保存できませんでした"

    func summary(in range: ClosedRange<LocalDate>) -> ReviewSummary {
        if let summary = cache.summaries[range] {
            return summary
        }

        let summary = ReviewSummary(entries: entries, in: range)

        cache.summaries[range] = summary

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
}
