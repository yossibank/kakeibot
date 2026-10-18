import Core
import Foundation
import Notifications
import Testing

struct NotificationSchedulerTests {
    @Test
    func addsUpcomingAndRemovesStale() async throws {
        let client = FakeCenter(pending: ["kakeibot.old", "other.app"])
        let scheduler = NotificationScheduler(client: client)
        let timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let now = Date(timeIntervalSince1970: 1_792_220_400)
        let today = try #require(LocalDate("2026-10-17"))
        let past = try #require(ReminderTime("09:00"))
        let later = try #require(ReminderTime("21:00"))

        let plan = [
            Self.reminder(on: today, at: past),
            Self.reminder(on: today, at: later)
        ]

        await scheduler.apply(plan, now: now, timeZone: timeZone)
        let state = await client.state
        let suffix = "21:00|今日の記録はまだです|本文"

        #expect(state.removed == ["kakeibot.old"])
        #expect(state.added.count == 1)
        #expect(state.added.first?.hasSuffix(suffix) == true)
        #expect(state.links == ["entry/2026-10-17"])
        #expect(state.requested)
    }

    @Test
    func keepsMatchingNotifications() async throws {
        let timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let now = Date(timeIntervalSince1970: 1_792_220_400)
        let today = try #require(LocalDate("2026-10-18"))
        let time = try #require(ReminderTime("21:00"))
        let notification = Self.reminder(on: today, at: time)
        let identifier = NotificationScheduler.prefix + notification.identifier
        let client = FakeCenter(pending: [identifier])
        let scheduler = NotificationScheduler(client: client)

        await scheduler.apply([notification], now: now, timeZone: timeZone)
        let state = await client.state

        #expect(state.added.isEmpty)
        #expect(state.removed.isEmpty)
    }
}

extension NotificationSchedulerTests {
    actor FakeCenter: NotificationCenterClient {
        struct State {
            var pending: [String]
            var added: [String] = []
            var removed: [String] = []
            var links: [String] = []
            var requested = false
        }

        private(set) var state: State

        init(pending: [String]) {
            self.state = State(pending: pending)
        }

        func pendingIdentifiers() async -> [String] {
            state.pending
        }

        func add(
            identifier: String,
            title: String,
            body: String,
            link: String,
            at components: DateComponents
        ) async throws {
            state.added.append(identifier)
            state.links.append(link)
        }

        func remove(_ identifiers: [String]) async {
            state.removed += identifiers
        }

        func authorization() async -> NotificationAuthorization {
            .notDetermined
        }

        func requestAuthorization() async -> Bool {
            state.requested = true
            return true
        }
    }
}

private extension NotificationSchedulerTests {
    static func reminder(
        on date: LocalDate,
        at time: ReminderTime
    ) -> PlannedNotification {
        PlannedNotification(
            key: "reminder",
            date: date,
            time: time,
            title: "今日の記録はまだです",
            body: "本文",
            route: .entry(date)
        )
    }
}
