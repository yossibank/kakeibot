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
        let state = State(checkTime: parts.clock.now, wait: parts.wait)
        let input = Input(today: today)

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = parts
    }
}

public extension ReviewModel {
    @MainActor
    @Observable
    final class Input {
        public internal(set) var today: LocalDate
        public internal(set) var scale: ReviewPeriod.Scale = .month
        public internal(set) var kind: ReviewKind = .expense
        public internal(set) var monthStartDay: MonthStartDay = .first
        public internal(set) var weekStart: Weekday = .sunday
        public internal(set) var budgets: [Budget] = []
        public internal(set) var carryoverFrom: YearMonth?
        public internal(set) var stampBook: StampBook?
        public internal(set) var list: Loadable<EntryList> = .loading
        public internal(set) var goals: [ReviewGoal] = []

        var reasons: [String: String] = [:]
        var notes: [String: String] = [:]
        var noSpendDays: Set<LocalDate> = []
        var recurrings: [Recurring] = []

        @ObservationIgnored var reasonRequests: Set<String> = []
        @ObservationIgnored var noteRequests: Set<String> = []

        init(today: LocalDate) {
            self.today = today
        }
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

    struct Share: Equatable, Identifiable, Sendable {
        public let id: Key
        public let name: String
        public let icon: Icon?
        public let amount: Int
        public let ratio: Double
        public let usage: BudgetUsage?
    }
}

public extension ReviewModel {
    static let loadFailedMessage = "記録を読めませんでした"

    func run() async {
        await loadSelection()

        let database = dependencies.database

        await observeAll([
            {
                await self.observe(
                    database.entryListUpdates(),
                    into: \.input.list
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
            state.notices.error.show(Self.loadFailedMessage)
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
            state.notices.error.show(Self.saveFailedMessage, for: error)
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

public extension ReviewModel.Share {
    enum Key: Hashable, Sendable {
        case category(EntryCategory.ID)
        case wallet(Wallet.ID)
        case recurring
        case move(ReviewModel.MoveKey)
        case factor(ReviewModel.FactorKey)
        case month(ReviewModel.MonthKey)
    }
}

public extension ReviewModel.Output {
    var period: ReviewPeriod {
        let current = ReviewPeriod(
            scale: input.scale,
            containing: input.today,
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
        summary(in: period.comparisonRange(today: input.today))
    }

    var isComparingPartially: Bool {
        period.range.contains(input.today)
    }

    var hasPreviousEntries: Bool {
        let range = period.comparisonRange(today: input.today)
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
        switch share.id {
        case let .move(key):
            return moveRows(to: key.walletId)
        case let .factor(key):
            return factorRows(of: key)
        case let .month(key):
            return monthRows(of: key)
        case .category, .wallet, .recurring:
            break
        }

        guard
            let list = input.list.value,
            let type = entryType
        else {
            return []
        }

        return entries
            .filter { entry in
                entry.type == type
                    && period.range.contains(entry.date)
                    && share.id.contains(entry)
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
        input.list.value?.days.first { $0.date == date }
    }

    func canMove(by count: Int) -> Bool {
        state.offset + count <= 0
    }
}

extension ReviewModel.Output {
    var entries: [Entry] {
        input.list.value?.entries ?? []
    }
}

extension ReviewModel.Share.Key {
    func contains(_ entry: Entry) -> Bool {
        switch self {
        case let .category(id): entry.categoryId == id
        case let .wallet(id): entry.walletId == id
        case .recurring: entry.recurringId != nil
        case .move, .factor, .month: false
        }
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

extension ReviewModel: TabScreenModel {
    public var isLoadFailed: Bool {
        input.list.isFailed
    }

    public func setToday(_ today: LocalDate) {
        if input.today != today {
            input.today = today
        }
    }
}
