import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class ReviewModel: ScreenModel {
    public let state: State
    public let input: Input
    public let output: Output

    let dependencies: Dependencies

    public init(
        database: AppDatabase,
        clock: ScreenClock,
        today: LocalDate
    ) {
        let state = State(today: today)
        let input = Input()

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = Dependencies(database: database, clock: clock)
    }
}

public extension ReviewModel {
    @MainActor
    @Observable
    final class State: NoticeHolding {
        public internal(set) var errorNotice = ErrorNotice()

        public var today: LocalDate

        public private(set) var scale: ReviewPeriod.Scale = .month
        public private(set) var offset = 0
        public private(set) var isMovingForward = true

        public internal(set) var kind: ReviewKind = .expense
        public internal(set) var showsStoreReviewCard = false
        public internal(set) var newReportKey: String?

        init(today: LocalDate) {
            self.today = today
        }
    }

    @MainActor
    @Observable
    final class Input {
        public internal(set) var isListFailed = false
        public internal(set) var monthStartDay: MonthStartDay = .first
        public internal(set) var weekStart: Weekday = .sunday
        public internal(set) var budgets: [Budget] = []
        public internal(set) var carryoverFrom: YearMonth?
        public internal(set) var stampBook: StampBook?
        public internal(set) var list: EntryList?
        public internal(set) var goals: [ReviewGoal] = []

        var reasons: [String: String] = [:]
        var notes: [String: String] = [:]
        var noSpendDays: Set<LocalDate> = []
        var recurrings: [Recurring] = []

        @ObservationIgnored var reasonRequests: Set<String> = []
        @ObservationIgnored var noteRequests: Set<String> = []
    }

    @MainActor
    final class Output {
        let input: Input
        let state: State
        let summaries = DerivedTable<ClosedRange<LocalDate>, ReviewSummary>()
        let moveLists = DerivedTable<ClosedRange<LocalDate>, [Move]>()
        let upcomingTotals = DerivedTable<ClosedRange<LocalDate>, Int>()
        let closingContents = DerivedTable<ClosingKey, ReviewClosingView.Content>()

        var entries: [Entry] {
            input.list?.entries ?? []
        }

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }
    }

    func run() async {
        await loadSelection()

        let database = dependencies.database

        await observeAll([
            {
                await self.observe(
                    database.entryListUpdates(),
                    into: \.input.list,
                    failing: \.input.isListFailed
                )
            },
            {
                await self.observe(database.budgetUpdates(), into: \.input.budgets)
            },
            {
                await self.observe(database.stampBookUpdates(), into: \.input.stampBook)
            },
            {
                await self.observe(database.noSpendDayUpdates(), into: \.input.noSpendDays)
            },
            {
                await self.observe(database.recurringUpdates(), into: \.input.recurrings)
            },
            {
                await self.observe(
                    database.settingUpdates(.monthStartDay),
                    into: \.input.monthStartDay
                )
            },
            {
                await self.observe(
                    database.settingUpdates(.budgetCarryoverFrom),
                    into: \.input.carryoverFrom
                )
            },
            {
                await self.observe(database.settingUpdates(.weekStart), into: \.input.weekStart)
            }
        ])
    }

    func loadSelection() async {
        do {
            let scale = try await dependencies.database.setting(.reviewScale)

            state.load(scale)
            state.kind = try await dependencies.database.setting(.reviewKind)
        } catch {
            state.errorNotice.show(Self.loadFailedMessage)
        }
    }

    func setScale(_ scale: ReviewPeriod.Scale) {
        state.setScale(scale)
    }

    func setKind(_ kind: ReviewKind) {
        state.kind = kind
    }

    func saveSelection() async {
        do {
            try await dependencies.database.setSetting(.reviewScale, to: state.scale)
            try await dependencies.database.setSetting(.reviewKind, to: state.kind)
        } catch {
            state.errorNotice.show(Self.saveFailedMessage, for: error)
        }
    }

    func move(by count: Int) {
        state.move(by: count)
    }

    func moveToCurrent() {
        state.moveToCurrent()
    }
}

extension ReviewModel.State {
    func load(_ scale: ReviewPeriod.Scale) {
        self.scale = scale
    }

    func setScale(_ scale: ReviewPeriod.Scale) {
        let scales = ReviewPeriod.Scale.allCases
        let from = scales.firstIndex(of: self.scale) ?? 0
        let to = scales.firstIndex(of: scale) ?? 0

        isMovingForward = to > from
        self.scale = scale
        offset = 0
    }

    func move(by count: Int) {
        guard offset + count <= 0 else {
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
    struct Dependencies {
        let database: AppDatabase
        let clock: ScreenClock
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
}

public extension ReviewModel.Output {
    var period: ReviewPeriod {
        let current = ReviewPeriod(
            scale: state.scale,
            containing: state.today,
            monthStartDay: input.monthStartDay,
            weekStart: input.weekStart
        )

        return current.adding(state.offset)
    }

    var canMoveForward: Bool {
        state.offset < 0
    }

    var isCurrentPeriod: Bool {
        state.offset == 0
    }

    var summary: ReviewSummary {
        summary(in: period.range)
    }

    var previousSummary: ReviewSummary {
        summary(in: period.comparisonRange(today: state.today))
    }

    var isComparingPartially: Bool {
        period.range.contains(state.today)
    }

    var hasPreviousEntries: Bool {
        let range = period.comparisonRange(today: state.today)
        return entries.contains { range.contains($0.date) }
    }

    var total: Int {
        total(of: state.kind)
    }

    var change: Int {
        change(of: state.kind)
    }

    var stampTallies: [StampBook.Tally] {
        input.stampBook?.tallies(in: period.range) ?? []
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

    func rows(for share: ReviewModel.Share) -> [EntryRowItem] {
        if let key = share.id.base as? ReviewModel.MoveKey {
            return moveRows(to: key.walletId)
        }

        if let key = share.id.base as? ReviewModel.FactorKey {
            return factorRows(of: key)
        }

        if let key = share.id.base as? ReviewModel.MonthKey {
            return monthRows(of: key)
        }

        guard
            let list = input.list,
            let type = entryType
        else {
            return []
        }

        return entries
            .filter { entry in
                let category = entry.categoryId.map(AnyHashable.init)
                let wallet = AnyHashable(entry.walletId)

                let isRecurring = share.id == ReviewModel.recurringShareId
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
        input.stampBook?.days(of: tally, in: period.range) ?? []
    }

    func day(on date: LocalDate) -> EntryDay? {
        input.list?.days.first { $0.date == date }
    }

    func canMove(by count: Int) -> Bool {
        state.offset + count <= 0
    }
}

extension ReviewModel.Output {
    var entryType: Entry.Kind? {
        state.kind.entryType
    }
}

extension ReviewModel {
    static let loadFailedMessage = "記録を読めませんでした"
}

private extension ReviewModel {
    static let saveFailedMessage = "保存できませんでした"
}

private extension ReviewModel.Output {
    func summary(in range: ClosedRange<LocalDate>) -> ReviewSummary {
        summaries.value(for: range) {
            ReviewSummary(entries: entries, in: range)
        }
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
