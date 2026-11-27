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

    let dependencies: ScreenParts

    public init(
        parts: ScreenParts,
        today: LocalDate
    ) {
        let state = State(month: today.yearMonth, wait: parts.wait)
        let input = Input(today: today)

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = parts
    }
}

public extension RecordsModel {
    func open(_ date: LocalDate) {
        state.open(date, in: date.periodMonth(startingOn: input.monthStartDay))
        input.layout = .calendar
    }

    func openCurrentMonth() {
        state.openMonth(output.currentMonth)
    }

    func loadLayout() async {
        do {
            input.layout = try await dependencies.database.setting(.recordsLayout)
        } catch {
            state.notices.error.show(Self.loadFailedMessage)
        }
    }

    func chooseLayout(_ layout: RecordsLayout) {
        input.layout = layout
    }

    func saveLayout() async {
        do {
            try await dependencies.database.setSetting(.recordsLayout, to: input.layout)
        } catch {
            state.notices.error.show(Self.saveFailedMessage, for: error)
        }
    }

    func load() async {
        do {
            input.list = try await .loaded(dependencies.database.entryList())
            input.recurrings = try await dependencies.database.recurrings()
        } catch {
            state.notices.error.show(Self.loadFailedMessage)
        }
    }

    func run() async {
        await loadLayout()

        await observeAll([
            {
                await self.observe(
                    self.dependencies.database.entryListUpdates(),
                    into: \.input.list
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
    public static let loadFailedMessage = "記録を読めませんでした"

    static let saveFailedMessage = "保存できませんでした"
    static let confirmDeleteThreshold = 10
    static let clearedSearchesDuration: Duration = .seconds(5)
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
            state.setMonth(input.today.periodMonth(startingOn: startDay))
        }
    }
}

extension RecordsModel: TabScreenModel {
    public var isLoadFailed: Bool {
        input.list.isFailed
    }

    public func setToday(_ today: LocalDate) {
        if input.today != today {
            input.today = today
        }
    }
}
