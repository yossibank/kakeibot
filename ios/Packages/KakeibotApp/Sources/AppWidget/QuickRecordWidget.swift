import SwiftUI
import WidgetKit

public struct QuickRecordWidget: Widget {
    public var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "QuickRecordWidget",
            provider: QuickRecordWidgetProvider()
        ) { entry in
            QuickRecordWidgetView(entry: entry)
        }
        .configurationDisplayName("すぐ記録")
        .description("テンプレートを押すと、アプリを開かずに記録します")
        .supportedFamilies([.systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }

    public init() {}
}
