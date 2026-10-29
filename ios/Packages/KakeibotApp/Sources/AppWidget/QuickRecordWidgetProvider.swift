import Core
import Foundation
import Store
import WidgetKit

struct QuickRecordWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickRecordWidgetEntry {
        .sample(at: Date())
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping @Sendable (QuickRecordWidgetEntry) -> Void
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
        completion: @escaping @Sendable (Timeline<QuickRecordWidgetEntry>) -> Void
    ) {
        let isPreview = context.isPreview

        Task {
            let timeline = await Self.timeline(at: Date(), isPreview: isPreview)
            completion(timeline)
        }
    }
}

private extension QuickRecordWidgetProvider {
    static func timeline(
        at now: Date,
        isPreview: Bool
    ) async -> Timeline<QuickRecordWidgetEntry> {
        let today = LocalDate(now, in: .current)

        guard
            let database = try? AppDatabase.appGroupForReading(),
            let overview = try? await database.monthOverview(on: today),
            let templates = try? await database.templates()
        else {
            let entry: QuickRecordWidgetEntry = isPreview
                ? .sample(at: now)
                : .empty(at: now)

            let retry = now.addingTimeInterval(WidgetTimeline.retryInterval)

            return Timeline(entries: [entry], policy: .after(retry))
        }

        let look = await database.widgetLook()
        let style = await database.widgetStyle()
        let order = await (try? database.setting(.templateOrder)) ?? .manual
        let recordedId = await (try? database.setting(.widgetEntry))??.entryId

        let summary = QuickRecordWidgetSummary(
            overview,
            templates: templates,
            order: order,
            recordedId: recordedId
        )

        var entries = [
            QuickRecordWidgetEntry(
                date: now,
                summary: summary,
                look: look,
                style: style
            )
        ]

        if let recorded = summary.recorded(at: now) {
            let clearedSummary = summary.clearingRecorded()

            let cleared = QuickRecordWidgetEntry(
                date: recorded.until,
                summary: clearedSummary,
                look: look,
                style: style
            )

            entries.append(cleared)
        }

        guard let midnight = WidgetTimeline.nextMidnight(after: now) else {
            return Timeline(entries: entries, policy: .never)
        }

        let nextDay = today.adding(days: 1)
        let nextOverview = overview.moved(to: nextDay)

        let tomorrow = QuickRecordWidgetSummary(
            nextOverview,
            templates: templates,
            order: order,
            recordedId: nil
        )

        let next = QuickRecordWidgetEntry(
            date: midnight,
            summary: tomorrow,
            look: look,
            style: style
        )

        return Timeline(entries: entries + [next], policy: .atEnd)
    }
}
