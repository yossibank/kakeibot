import Core
import Foundation
import Store
import WidgetKit

struct BudgetWidgetProvider: WidgetTimelineProvider {
    typealias Entry = BudgetWidgetEntry
}

extension BudgetWidgetProvider {
    static func timeline(
        at now: Date,
        isPreview: Bool
    ) async -> Timeline<BudgetWidgetEntry> {
        let today = LocalDate(now, in: .current)

        guard
            let database = try? AppDatabase.appGroupForReading(),
            let overview = try? await database.widgetOverview(on: today)
        else {
            return fallbackTimeline(at: now, isPreview: isPreview)
        }

        let look = await database.widgetLook()
        let weekStart = await (try? database.setting(.weekStart)) ?? .sunday
        let style = await database.widgetStyle()
        let summary = BudgetWidgetSummary(overview, weekStart: weekStart)

        let current = BudgetWidgetEntry(
            date: now,
            summary: summary,
            look: look,
            style: style
        )

        guard let midnight = WidgetTimeline.nextMidnight(after: now) else {
            return Timeline(entries: [current], policy: .never)
        }

        let nextDay = today.adding(days: 1)
        let tomorrow = overview.moved(to: nextDay)
        let nextSummary = BudgetWidgetSummary(tomorrow, weekStart: weekStart)

        let next = BudgetWidgetEntry(
            date: midnight,
            summary: nextSummary,
            look: look,
            style: style
        )

        return Timeline(entries: [current, next], policy: .atEnd)
    }
}
