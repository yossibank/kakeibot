import Core
import Store

public extension HomeModel {
    @MainActor
    final class Output {
        let input: Input
        let state: State

        private let figuresCache = Derived<HomeFigures>()
        private let templatesCache = Derived<[EntryTemplate]>()

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }
    }
}

public extension HomeModel.Output {
    var overview: MonthOverview {
        figures.overview
    }

    var billPages: [BillPage] {
        figures.billPages
    }

    var billPage: Int {
        BillPage.clamped(state.billPage, in: billPages)
    }

    var templates: [EntryTemplate] {
        templatesCache.value {
            let shown = input.allTemplates.filter { $0.type == state.templateType }
            return input.list?.ordered(shown, by: input.templateOrder, today: state.today) ?? shown
        }
    }

    var monthStartDay: MonthStartDay {
        input.monthStartDay
    }

    var showsNoRecords: Bool {
        input.list != nil && recentRows.isEmpty
    }

    var recentRows: [EntryRowItem] {
        guard let list = input.list else {
            return []
        }

        var rows: [EntryRowItem] = []

        for day in list.days {
            let label = dayLabel(for: day.date)

            for entry in day.entries {
                guard rows.count < HomeModel.recentLimit else {
                    return rows
                }

                let row = EntryRowItem(entry, in: list, dayLabel: label)

                rows.append(row)
            }
        }

        return rows
    }

    var homeLayout: HomeLayout {
        HomeLayout(order: input.homeSections, hidden: input.homeHiddenSections)
    }
}

private extension HomeModel.Output {
    var figures: HomeFigures {
        figuresCache.value {
            let bills = input.list?.upcomingCardBills(
                recurrings: input.recurrings,
                after: state.today,
                count: BillPage.limit
            )

            let overview = MonthOverview(
                list: input.list,
                budgets: input.budgets,
                recurrings: input.recurrings,
                monthStartDay: input.monthStartDay,
                carryoverFrom: input.carryoverFrom,
                today: state.today
            )

            return HomeFigures(overview: overview, billPages: BillPage.pages(of: bills ?? []))
        }
    }

    func dayLabel(for date: LocalDate) -> String {
        switch date {
        case state.today: "今日"
        case state.today.adding(days: -1): "昨日"
        default: date.monthDayText
        }
    }
}

private struct HomeFigures {
    let overview: MonthOverview
    let billPages: [BillPage]
}
