import SwiftUI
import WidgetKit

public struct BudgetLockWidget: Widget {
    public var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "BudgetLockWidget",
            provider: BudgetWidgetProvider()
        ) { entry in
            BudgetLockWidgetView(entry: entry)
        }
        .configurationDisplayName("あといくら")
        .description("ロック画面に、今月あといくら使えるかを出します")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }

    public init() {}
}
