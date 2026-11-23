import Foundation
import WidgetKit

protocol WidgetTimelineProvider: TimelineProvider,
    SendableMetatype where Entry: WidgetFallbackEntry {
    static func timeline(at now: Date, isPreview: Bool) async -> Timeline<Entry>
}

extension WidgetTimelineProvider {
    static func fallbackTimeline(at now: Date, isPreview: Bool) -> Timeline<Entry> {
        let entry: Entry = isPreview
            ? .sample(at: now)
            : .empty(at: now)

        let retry = now.addingTimeInterval(WidgetTimeline.retryInterval)

        return Timeline(entries: [entry], policy: .after(retry))
    }

    func placeholder(in context: Context) -> Entry {
        .sample(at: Date())
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping @Sendable (Entry) -> Void
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
        completion: @escaping @Sendable (Timeline<Entry>) -> Void
    ) {
        let isPreview = context.isPreview

        Task {
            let timeline = await Self.timeline(at: Date(), isPreview: isPreview)
            completion(timeline)
        }
    }
}
