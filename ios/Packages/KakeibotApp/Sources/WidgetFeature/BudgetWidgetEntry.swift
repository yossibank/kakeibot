import Core
import Foundation
import WidgetKit

struct BudgetWidgetEntry: TimelineEntry {
    let date: Date
    let summary: BudgetWidgetSummary?
    let look: ThemeLook
}

extension BudgetWidgetEntry {
    static func empty(at date: Date) -> BudgetWidgetEntry {
        BudgetWidgetEntry(date: date, summary: nil, look: .followsDevice)
    }

    static func sample(at date: Date) -> BudgetWidgetEntry {
        let today = LocalDate(date, in: .current)

        return BudgetWidgetEntry(
            date: date,
            summary: .sample(on: today),
            look: .followsDevice
        )
    }
}
