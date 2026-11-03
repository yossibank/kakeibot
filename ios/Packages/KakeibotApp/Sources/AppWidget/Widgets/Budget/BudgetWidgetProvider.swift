import Core
import Foundation
import Store
import WidgetKit

struct BudgetWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BudgetWidgetEntry {
        .sample(at: Date())
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping @Sendable (BudgetWidgetEntry) -> Void
    ) {
        let isPreview = context.isPreview

        Task {
            let now = Date()
            let timeline = await Self.timeline(at: now, isPreview: isPreview)
            let entry = timeline.entries.first ?? .sample(at: now)
            completion(entry)
        }
    }

    func getTimeline(
        in context: Context,
        completion: @escaping @Sendable (Timeline<BudgetWidgetEntry>) -> Void
    ) {
        let isPreview = context.isPreview

        Task {
            let timeline = await Self.timeline(at: Date(), isPreview: isPreview)
            completion(timeline)
        }
    }
}

private extension BudgetWidgetProvider {
    static func timeline(
        at now: Date,
        isPreview: Bool
    ) async -> Timeline<BudgetWidgetEntry> {
        let today = LocalDate(now, in: .current)

        guard
            let database = try? AppDatabase.appGroupForReading(),
            let overview = try? await database.widgetOverview(on: today)
        else {
            let entry: BudgetWidgetEntry = isPreview
                ? .sample(at: now)
                : .empty(at: now)

            let retry = now.addingTimeInterval(WidgetTimeline.retryInterval)

            return Timeline(entries: [entry], policy: .after(retry))
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
