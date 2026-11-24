import SwiftUI

struct EntryTodayFollower: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase

    let model: EntryModel

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
                model.updateToday()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    model.updateToday()
                }
            }
    }
}
