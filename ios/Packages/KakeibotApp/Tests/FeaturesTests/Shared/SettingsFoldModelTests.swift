import Core
import FeatureModels
import Features
import Foundation
import Store
import Testing

@MainActor
struct SettingsFoldModelTests {
    @Test
    func keepsClosedHintPerScreen() async throws {
        let database = try AppDatabase.inMemory()
        let wallets = WalletListModel(parts: .system(database))
        let stamps = StampListModel(parts: .system(database))

        let unread = wallets.input.hint.isClosed

        await wallets.loadFold(\.hint)
        let openedFirst = wallets.input.hint.isClosed

        await wallets.setFold(\.hint, closed: true).value
        let reopened = WalletListModel(parts: .system(database))
        await reopened.loadFold(\.hint)
        await stamps.loadFold(\.hint)

        #expect(unread == nil)
        #expect(openedFirst == false)
        #expect(reopened.input.hint.isClosed == true)
        #expect(reopened.input.hiddenList.isClosed == nil)
        #expect(stamps.input.hint.isClosed == false)
    }

    @Test
    func remembersClosedHiddenList() async throws {
        let database = try AppDatabase.inMemory()
        let templates = TemplateListModel(parts: .system(database))

        await templates.loadFold(\.hiddenList)
        let openedFirst = templates.input.hiddenList.isClosed

        await templates.setFold(\.hiddenList, closed: true).value
        let reopened = TemplateListModel(parts: .system(database))
        await reopened.loadFold(\.hiddenList)
        await reopened.loadFold(\.hint)
        let closedAgain = reopened.input.hiddenList.isClosed

        await reopened.setFold(\.hiddenList, closed: false).value
        let openedAgain = TemplateListModel(parts: .system(database))
        await openedAgain.loadFold(\.hiddenList)

        #expect(openedFirst == false)
        #expect(closedAgain == true)
        #expect(reopened.input.hint.isClosed == false)
        #expect(openedAgain.input.hiddenList.isClosed == false)
    }

    @Test
    func sharesHintBetweenModelsOfOneScreen() async throws {
        let database = try AppDatabase.inMemory()
        let guide = SettingsHintModel(parts: .system(database), screen: .widgetGuide)
        let style = ThemeStyleModel(parts: .system(database))

        await guide.setFold(\.hint, closed: true).value
        await style.setFold(\.lookHint, closed: true).value

        let reopened = SettingsHintModel(parts: .system(database), screen: .widgetGuide)
        let icons = SettingsHintModel(parts: .system(database), screen: .appIcons)
        await reopened.loadFold(\.hint)
        await icons.loadFold(\.hint)
        await style.loadFold(\.textHint)

        #expect(reopened.input.hint.isClosed == true)
        #expect(icons.input.hint.isClosed == false)
        #expect(style.input.lookHint.isClosed == true)
        #expect(style.input.textHint.isClosed == false)
    }
}
