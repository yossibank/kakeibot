import Core
import Foundation
import Store
import WidgetKit

struct BudgetWidgetEntry: TimelineEntry {
    let date: Date
    let overview: MonthOverview?
    let look: ThemeLook
}

extension BudgetWidgetEntry {
    static func empty(at date: Date) -> BudgetWidgetEntry {
        BudgetWidgetEntry(date: date, overview: nil, look: .followsDevice)
    }
}
