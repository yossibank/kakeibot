import Core

struct MonthPlan: Equatable, Sendable {
    let budgets: [Budget]
    let recurrings: [Recurring]
    let monthStartDay: MonthStartDay
    let carryoverFrom: YearMonth?
    let today: LocalDate
}

extension MonthPlan {
    static let widgetMonths = 4

    var widgetStart: LocalDate {
        let periodStart = today
            .periodMonth(startingOn: monthStartDay)
            .period(startingOn: monthStartDay)
            .lowerBound

        let month = periodStart.yearMonth.adding(months: -Self.widgetMonths)
        let monthStart = month.period(startingOn: .first).lowerBound
        let templateStart = today.adding(days: -TemplateOrder.frequentDays)
        let start = min(monthStart, templateStart)

        guard let carryoverFrom else {
            return start
        }

        let carryoverStart = carryoverFrom.period(startingOn: monthStartDay).lowerBound

        return min(start, carryoverStart)
    }

    func overview(with list: EntryList) -> MonthOverview {
        MonthOverview(
            list: list,
            budgets: budgets,
            recurrings: recurrings,
            monthStartDay: monthStartDay,
            carryoverFrom: carryoverFrom,
            today: today
        )
    }
}
