import Core
import Foundation
import Store
import WidgetKit

struct BudgetWidgetProvider {}

private extension BudgetWidgetProvider {
    static let retryInterval: TimeInterval = 30 * 60

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
            let retry = now.addingTimeInterval(retryInterval)

            return Timeline(entries: [entry], policy: .after(retry))
        }

        let look = await (try? database.themeLook()) ?? .followsDevice

        let current = BudgetWidgetEntry(
            date: now,
            summary: BudgetWidgetSummary(overview),
            look: look
        )

        guard let midnight = nextMidnight(after: now) else {
            return Timeline(entries: [current], policy: .never)
        }

        let tomorrow = overview.moved(to: today.adding(days: 1))

        let next = BudgetWidgetEntry(
            date: midnight,
            summary: BudgetWidgetSummary(tomorrow),
            look: look
        )

        return Timeline(entries: [current, next], policy: .atEnd)
    }

    static func nextMidnight(after date: Date) -> Date? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: start)
    }
}

extension BudgetWidgetProvider: TimelineProvider {
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
