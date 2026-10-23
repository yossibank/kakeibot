import AppWidget
import SwiftUI
import WidgetKit

@main
struct KakeibotWidgetBundle: WidgetBundle {
    var body: some Widget {
        BudgetWidget()
        BudgetLockWidget()
        QuickRecordWidget()
        RecordEntryControl()
    }

    init() {
        WidgetFonts.register()
    }
}
