import DesignSystem
import Store
import SwiftUI
import WidgetKit

@MainActor
public struct KakeibotWidget {
    public init() {}
}

extension KakeibotWidget: Widget {
    public var body: some WidgetConfiguration {
        let provider = Provider()

        return StaticConfiguration(kind: "KakeibotWidget", provider: provider) { _ in
            Text("Kakeibot")
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Kakeibot")
    }
}

private struct Provider {}

extension Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: .now)
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (SimpleEntry) -> Void
    ) {
        let entry = SimpleEntry(date: .now)
        completion(entry)
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<SimpleEntry>) -> Void
    ) {
        let entry = SimpleEntry(date: .now)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

private struct SimpleEntry: TimelineEntry {
    let date: Date
}
