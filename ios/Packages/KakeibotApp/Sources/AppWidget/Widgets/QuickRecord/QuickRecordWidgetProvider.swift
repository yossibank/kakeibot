import Core
import Foundation
import Store
import WidgetKit

struct QuickRecordWidgetProvider: WidgetTimelineProvider {
    typealias Entry = QuickRecordWidgetEntry
}

extension QuickRecordWidgetProvider {
    static func timeline(
        at now: Date,
        isPreview: Bool
    ) async -> Timeline<QuickRecordWidgetEntry> {
        let today = LocalDate(now, in: .current)
        let database = try? AppDatabase.appGroupForReading()
        let recordedId = await (try? database?.setting(.widgetEntry))??.entryId

        guard
            let database,
            let overview = try? await database.widgetOverview(on: today, including: recordedId),
            let templates = try? await database.templates()
        else {
            return fallbackTimeline(at: now, isPreview: isPreview)
        }

        let look = await database.widgetLook()
        let style = await database.widgetStyle()
        let order = await (try? database.setting(.templateOrder)) ?? .manual

        let summary = QuickRecordWidgetSummary(
            overview,
            templates: templates,
            order: order,
            recordedId: recordedId
        )

        let entries = currentEntries(
            of: summary,
            at: now,
            look: look,
            style: style
        )

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

private extension QuickRecordWidgetProvider {
    static func currentEntries(
        of summary: QuickRecordWidgetSummary,
        at now: Date,
        look: ThemeLook,
        style: ThemeStyle
    ) -> [QuickRecordWidgetEntry] {
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

        return entries
    }
}
