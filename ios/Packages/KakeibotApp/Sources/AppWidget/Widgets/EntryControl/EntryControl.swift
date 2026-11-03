import SwiftUI
import WidgetKit

public struct EntryControl: ControlWidget {
    public var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "RecordEntryControl") {
            ControlWidgetButton(action: EntryControlIntent()) {
                Label("記録する", systemImage: "square.and.pencil")
            }
        }
        .displayName("記録する")
        .description("今日の入力シートを開きます")
    }

    public init() {}
}
