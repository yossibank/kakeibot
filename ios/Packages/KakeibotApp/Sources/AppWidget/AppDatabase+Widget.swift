import Core
import Foundation
import Notifications
import Store
import WidgetKit

extension AppDatabase {
    func widgetLook() async -> ThemeLook {
        await (try? themeLook()) ?? .followsDevice
    }

    func widgetStyle() async -> ThemeStyle {
        var style = await (try? style()) ?? .standard

        style.textSize = .standard

        return style
    }

    func finishWidgetWrite(today: LocalDate) async {
        if let input = try? await notificationInput(from: today) {
            let plan = input.plan(today: today)

            await NotificationScheduler().apply(plan, now: Date(), timeZone: .current)
        }

        WidgetCenter.shared.reloadAllTimelines()
    }
}
