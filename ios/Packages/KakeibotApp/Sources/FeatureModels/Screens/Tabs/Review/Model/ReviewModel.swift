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

    let dependencies: ScreenParts

    public init(
        parts: ScreenParts,
        today: LocalDate
    ) {
        let state = State(today: today, checkTime: parts.clock.now)
        let input = Input()

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = parts
    }
}

public extension ReviewModel {
    @MainActor
    @Observable
    final class State: NoticeHolding {
        public var errorNotice = ErrorNotice()
        public var today: LocalDate
        public var sheet: Sheet?
        public var analysisShare: Share?

        public internal(set) var checkTime: Date
        public internal(set) var pending: Opening?

        public private(set) var offset = 0
        public private(set) var isMovingForward = true

        public internal(set) var showsStoreReviewCard = false
        public internal(set) var newReportKey: String?

        init(
            today: LocalDate,
            checkTime: Date
        ) {
            self.today = today
            self.checkTime = checkTime
        }
    }

    @MainActor
    @Observable
    final class Input {
        public internal(set) var scale: ReviewPeriod.Scale = .month
        public internal(set) var kind: ReviewKind = .expense
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
        let closingContents = DerivedTable<ClosingKey, ReviewClosing.Content>()

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }
    }

    struct Share: Identifiable {
        public let id: AnyHashable
        public let name: String
        public let icon: Icon?
        public let amount: Int
        public let ratio: Double
        public let usage: BudgetUsage?
    }
}

public extension ReviewModel {
    static let recurringShareId = AnyHashable("recurring")
    static let loadFailedMessage = "記録を読めませんでした"

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
            input.scale = try await dependencies.database.setting(.reviewScale)
            input.kind = try await dependencies.database.setting(.reviewKind)
        } catch {
            state.errorNotice.show(Self.loadFailedMessage)
        }
    }

    func setScale(_ scale: ReviewPeriod.Scale) {
        let scales = ReviewPeriod.Scale.allCases
        let from = scales.firstIndex(of: input.scale) ?? 0
        let to = scales.firstIndex(of: scale) ?? 0

        state.restart(movingForward: to > from)
        input.scale = scale
    }

    func setKind(_ kind: ReviewKind) {
        input.kind = kind
    }

    func saveSelection() async {
        do {
            try await dependencies.database.setSetting(.reviewScale, to: input.scale)
            try await dependencies.database.setSetting(.reviewKind, to: input.kind)
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

private extension ReviewModel {
    static let saveFailedMessage = "保存できませんでした"
}

public extension ReviewModel.Output {
    var period: ReviewPeriod {
        let current = ReviewPeriod(
            scale: input.scale,
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
        total(of: input.kind)
    }

    var change: Int {
        change(of: input.kind)
    }

    var stampTallies: [StampBook.Tally] {
        input.stampBook?.tallies(in: period.range) ?? []
    }

    var entryType: Entry.Kind? {
        input.kind.entryType
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
    var entries: [Entry] {
        input.list?.entries ?? []
    }
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

extension ReviewModel.State {
    func restart(movingForward isMovingForward: Bool) {
        self.isMovingForward = isMovingForward
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
