import Core
import Foundation
import WidgetKit

struct QuickRecordWidgetEntry: TimelineEntry {
    let date: Date
    let summary: QuickRecordWidgetSummary?
    let look: ThemeLook
    let style: ThemeStyle
}

extension QuickRecordWidgetEntry {
    static func empty(at date: Date) -> QuickRecordWidgetEntry {
        QuickRecordWidgetEntry(
            date: date,
            summary: nil,
            look: .followsDevice,
            style: .standard
        )
    }

    static func sample(at date: Date) -> QuickRecordWidgetEntry {
        QuickRecordWidgetEntry(
            date: date,
            summary: .sample(),
            look: .followsDevice,
            style: .standard
        )
    }
}
