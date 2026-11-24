import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class RecordsModel: ScreenModel {
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

public extension RecordsModel {
    func open(_ date: LocalDate) {
        state.open(date, in: date.periodMonth(startingOn: input.monthStartDay))
    }

    func openCurrentMonth() {
        state.openMonth(output.currentMonth)
    }

    func loadLayout() async {
        do {
            try await state.setLayout(dependencies.database.setting(.recordsLayout))
        } catch {
            state.errorNotice.show(Self.loadFailedMessage)
        }
    }

    func saveLayout() async {
        do {
            try await dependencies.database.setSetting(.recordsLayout, to: state.layout)
        } catch {
            state.errorNotice.show(Self.saveFailedMessage, for: error)
        }
    }

    func load() async {
        do {
            input.list = try await dependencies.database.entryList()
            input.recurrings = try await dependencies.database.recurrings()
        } catch {
            state.errorNotice.show(Self.loadFailedMessage)
        }
    }

    func run() async {
        await loadLayout()

        await observeAll([
            {
                await self.observe(
                    self.dependencies.database.entryListUpdates(),
                    into: \.input.list,
                    failing: \.input.isListFailed
                )
            },
            {
                await self.observe(
                    self.dependencies.database.noSpendDayUpdates(),
                    into: \.input.noSpendDays
                )
            },
            {
                await self.observe(
                    self.dependencies.database.stampBookUpdates(),
                    into: \.input.stampBook
                )
            },
            {
                await self.observe(
                    self.dependencies.database.shelfIconListUpdates(),
                    into: \.input.stampShelf
                )
            },
            {
                await self.observe(
                    self.dependencies.database.rewardBankUpdates(),
                    into: \.input.rewardBank
                )
            },
            {
                await self.observe(
                    self.dependencies.database.recurringUpdates(),
                    into: \.input.recurrings
                )
            },
            {
                await self.observe(
                    self.dependencies.database.settingUpdates(.weekStart),
                    into: \.input.weekStart
                )
            },
            {
                await self.observeMonthStartDay()
            },
            {
                await self.observe(
                    self.dependencies.database.settingUpdates(.recentSearches),
                    into: \.input.recentSearches
                )
            }
        ])
    }
}

extension RecordsModel {
    struct Dependencies {
        let database: AppDatabase
        let clock: ScreenClock
    }

    static let loadFailedMessage = "記録を読めませんでした"
    static let saveFailedMessage = "保存できませんでした"
    static let confirmDeleteThreshold = 10
}

private extension RecordsModel {
    func observeMonthStartDay() async {
        await observe(
            dependencies.database.settingUpdates(.monthStartDay),
            failure: Self.loadFailedMessage
        ) { startDay in
            guard startDay != input.monthStartDay else {
                return
            }

            input.monthStartDay = startDay
            state.setMonth(state.today.periodMonth(startingOn: startDay))
        }
    }
}
