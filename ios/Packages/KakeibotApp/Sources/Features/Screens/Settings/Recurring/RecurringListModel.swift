import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class RecurringListModel {
    public let state: State
    public let input: Input
    public let output: Output

    let dependencies: SettingsBoardDependencies

    public init(
        database: AppDatabase,
        clock: ScreenClock,
        today: LocalDate
    ) {
        let state = State()
        let input = Input(today: today)

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = SettingsBoardDependencies(database: database, clock: clock)
    }
}

public extension RecurringListModel {
    @MainActor
    @Observable
    final class State: SettingsBoardState {
        public var errorNotice = ErrorNotice()

        public var type: Entry.Kind = .expense
        public var movingOrder: [Recurring.ID]?
    }

    @MainActor
    @Observable
    final class Input: SettingsBoardInput {
        public internal(set) var snapshot: [Recurring]?
        public internal(set) var list: EntryList?
        public internal(set) var monthStartDay: MonthStartDay = .first

        let today: LocalDate

        init(today: LocalDate) {
            self.today = today
        }
    }

    static func title(of type: Entry.Kind) -> String {
        type == .transfer ? "振替" : "固定費"
    }

    func observe() async {
        await observeAll([
            {
                await self.observe(self.updates(), into: \.input.snapshot)
            },
            {
                await self.observe(
                    self.dependencies.database.entryListUpdates(),
                    into: \.input.list
                )
            },
            {
                await self.observe(
                    self.dependencies.database.settingUpdates(.monthStartDay),
                    into: \.input.monthStartDay
                )
            }
        ])
    }
}

extension RecurringListModel: SettingsBoardListModel {
    typealias Item = Recurring

    static let loadFailedMessage = "固定費を読めませんでした"

    func read() async throws -> [Recurring] {
        try await dependencies.database.recurrings(includingHidden: true)
    }

    func updates() -> some AsyncSequence<[Recurring], any Error> {
        dependencies.database.recurringUpdates(includingHidden: true)
    }

    func board() -> RecurringBoard {
        RecurringBoard(model: self, database: dependencies.database, clock: dependencies.clock)
    }
}

extension RecurringListModel: SettingsBoardModel {
    public func saveOrder(_ ids: [Recurring.ID]) async throws {
        let others = (input.snapshot ?? []).map(\.id).filter { !ids.contains($0) }
        let ordered = ids + others

        try await dependencies.database.reorder(ordered, at: dependencies.clock.now)
    }

    public func saveHidden(
        _ id: Recurring.ID,
        isHidden: Bool
    ) async throws {
        try await dependencies.database.setRecurringHidden(
            id,
            isHidden: isHidden,
            today: input.today,
            at: dependencies.clock.now
        )
    }

    public func remove(_ id: Recurring.ID) async throws -> Deletion {
        try await dependencies.database.deleteRecurring(id, at: dependencies.clock.now)
    }
}
