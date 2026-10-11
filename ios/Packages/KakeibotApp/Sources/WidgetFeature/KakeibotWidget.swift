import DesignSystem
import Store
import SwiftUI
import WidgetKit

public struct KakeibotWidget: Widget {
    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: "KakeibotWidget", provider: Provider()) { _ in
            Text("Kakeibot")
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Kakeibot")
    }
}

private struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: .now)
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (SimpleEntry) -> Void
    ) {
        completion(SimpleEntry(date: .now))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<SimpleEntry>) -> Void
    ) {
        completion(Timeline(entries: [SimpleEntry(date: .now)], policy: .never))
    }
}

private struct SimpleEntry: TimelineEntry {
    let date: Date
}
