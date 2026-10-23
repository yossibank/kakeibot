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

            completion(timeline.entries.first ?? .sample(at: now))
        }
    }

    func getTimeline(
        in context: Context,
        completion: @escaping @Sendable (Timeline<BudgetWidgetEntry>) -> Void
    ) {
        let isPreview = context.isPreview

        Task {
            await completion(Self.timeline(at: Date(), isPreview: isPreview))
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
            let overview = try? await database.monthOverview(on: today)
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

        let current = BudgetWidgetEntry(
            date: now,
            summary: BudgetWidgetSummary(overview, weekStart: weekStart),
            look: look,
            style: style
        )

        guard let midnight = WidgetTimeline.nextMidnight(after: now) else {
            return Timeline(entries: [current], policy: .never)
        }

        let tomorrow = overview.moved(to: today.adding(days: 1))

        let next = BudgetWidgetEntry(
            date: midnight,
            summary: BudgetWidgetSummary(tomorrow, weekStart: weekStart),
            look: look,
            style: style
        )

        return Timeline(entries: [current, next], policy: .atEnd)
    }
}
