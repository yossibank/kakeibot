import Core
import FeatureModels
import Features
import Foundation
import Store
import Testing
import TestSupport

@MainActor
struct SettingsMenuModelTests {
    @Test
    func followsChangedSettings() async throws {
        let setup = try await HomeModelTests.Setup()
        let startDay = try #require(MonthStartDay(25))
        let model = SettingsMenuModel(parts: .system(setup.database))

        let task = Task {
            await model.run()
        }

        await ObservationWait.until {
            model.input.usesFun != nil
        }

        let startDayFirst = model.input.monthStartDay
        let reminderFirst = model.input.reminderTime

        try await setup.database.setSetting(.monthStartDay, to: startDay)
        try await setup.database.setSetting(.launchScreen, to: .review)
        try await setup.database.setSetting(.reminderTime, to: .evening)
        try await setup.database.setSetting(.theme, to: .preset(.sky))

        await ObservationWait.until {
            model.input.monthStartDay == startDay
                && model.input.launchScreen == .review
                && model.input.reminderTime == .evening
                && model.input.theme == .preset(.sky)
        }

        task.cancel()

        #expect(startDayFirst == .first)
        #expect(reminderFirst == nil)
        #expect(model.input.monthStartDay == startDay)
        #expect(model.input.launchScreen == .review)
        #expect(model.input.reminderTime == .evening)
        #expect(model.input.theme == .preset(.sky))
    }

    @Test
    func tellsBackupAgeAfterExport() async throws {
        let setup = try await HomeModelTests.Setup()
        let now = Date()
        let parts = ScreenParts(database: setup.database, clock: .fixed(now))
        let model = SettingsMenuModel(parts: parts)

        let task = Task {
            await model.run()
        }

        let unsaved = model.backupText()
        let exportedAt = try #require(Calendar.current.date(byAdding: .month, value: -2, to: now))

        try await setup.database.setSetting(.backupExportedAt, to: exportedAt)

        await ObservationWait.until {
            model.input.backupExportedAt != nil
        }

        task.cancel()

        #expect(unsaved == nil)
        #expect(model.backupText() == "2 か月前")
    }

    @Test
    func readsNotificationAuthorization() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = SettingsMenuModel(parts: .system(setup.database))

        let denied = NotificationPermission {
            .denied
        } request: {
            false
        }

        let start = model.input.authorization
        await model.loadAuthorization(denied)

        #expect(start == .allowed)
        #expect(model.input.authorization == .denied)
    }
}
