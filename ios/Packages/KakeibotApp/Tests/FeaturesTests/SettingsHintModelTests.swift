import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct SettingsHintModelTests {
    @Test
    func keepsClosedHintPerScreen() async throws {
        let database = try AppDatabase.inMemory()
        let wallets = SettingsHintModel(database: database, hint: .wallets)
        let budgets = SettingsHintModel(database: database, hint: .budgets)

        await wallets.load()
        let openedFirst = !wallets.isClosed

        await wallets.close()
        let reopened = SettingsHintModel(database: database, hint: .wallets)
        await reopened.load()
        await budgets.load()

        #expect(openedFirst)
        #expect(reopened.isClosed)
        #expect(!budgets.isClosed)
    }
}
