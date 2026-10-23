import SwiftUI
import WidgetKit

public struct BudgetWidget: Widget {
    public var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "BudgetWidget",
            provider: BudgetWidgetProvider()
        ) { entry in
            BudgetWidgetView(entry: entry)
        }
        .configurationDisplayName("あといくら")
        .description("今月あといくら使えるかと、今日の支出を出します")
        .supportedFamilies([.systemSmall, .systemMedium])
    }

    public init() {}
}
