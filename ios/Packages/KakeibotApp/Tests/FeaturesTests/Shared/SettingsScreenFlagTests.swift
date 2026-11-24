import Core
import FeatureModels
import Features
import Foundation
import Store
import Testing

@MainActor
struct SettingsScreenFlagTests {
    @Test
    func keepsClosedHintPerScreen() async throws {
        let database = try AppDatabase.inMemory()
        let wallets = SettingsScreenFlag.closedHint(.wallets, in: .system(database))
        let budgets = SettingsScreenFlag.closedHint(.budgets, in: .system(database))

        await wallets.load()
        let openedFirst = !wallets.isOn

        await wallets.set(true).value
        let reopened = SettingsScreenFlag.closedHint(.wallets, in: .system(database))
        await reopened.load()
        await budgets.load()

        #expect(openedFirst)
        #expect(reopened.isOn)
        #expect(!budgets.isOn)
    }

    @Test
    func remembersOpenHiddenList() async throws {
        let database = try AppDatabase.inMemory()
        let templates = SettingsScreenFlag.openHiddenList(.templates, in: .system(database))

        await templates.load()
        let openedFirst = templates.isOn

        await templates.set(false).value
        let reopened = SettingsScreenFlag.openHiddenList(.templates, in: .system(database))
        await reopened.load()
        let closedAgain = !reopened.isOn

        await reopened.set(true).value
        let openedAgain = SettingsScreenFlag.openHiddenList(.templates, in: .system(database))
        await openedAgain.load()

        #expect(openedFirst)
        #expect(closedAgain)
        #expect(openedAgain.isOn)
    }
}
