import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct SettingsScreenFlagTests {
    @Test
    func keepsClosedHintPerScreen() async throws {
        let database = try AppDatabase.inMemory()
        let wallets = SettingsScreenFlag.closedHint(.wallets, in: database)
        let budgets = SettingsScreenFlag.closedHint(.budgets, in: database)

        await wallets.load()
        let openedFirst = !wallets.isOn

        await wallets.set(true)
        let reopened = SettingsScreenFlag.closedHint(.wallets, in: database)
        await reopened.load()
        await budgets.load()

        #expect(openedFirst)
        #expect(reopened.isOn)
        #expect(!budgets.isOn)
    }

    @Test
    func remembersOpenHiddenList() async throws {
        let database = try AppDatabase.inMemory()
        let templates = SettingsScreenFlag.openHiddenList(
            .templates,
            in: database
        )

        await templates.load()
        let closedFirst = !templates.isOn

        await templates.set(true)
        let reopened = SettingsScreenFlag.openHiddenList(
            .templates,
            in: database
        )
        await reopened.load()
        let openedAgain = reopened.isOn

        await reopened.set(false)
        let closedAgain = SettingsScreenFlag.openHiddenList(
            .templates,
            in: database
        )
        await closedAgain.load()

        #expect(closedFirst)
        #expect(openedAgain)
        #expect(!closedAgain.isOn)
    }
}
