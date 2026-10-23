import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class SetupModel: ScreenModel {
    public private(set) var progress: SetupProgress?
    public private(set) var isCardClosed = true
    public private(set) var isCustomizeCardClosed = true
    public private(set) var isEntryOpened = true
    public private(set) var isSettingsOpened = true
    public private(set) var launchScreen: LaunchScreen = .home
    public private(set) var startsWithAmount = true
    public private(set) var theme: ThemeChoice = .system
    public private(set) var customThemes: [Theme] = []

    public internal(set) var errorNotice = ErrorNotice()

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension SetupModel {
    var cardItems: [SetupItem] {
        guard let progress else {
            return []
        }

        return SetupItem.home.filter { !$0.isDone(in: progress) }
    }

    var showsCard: Bool {
        !isCardClosed && !cardItems.isEmpty
    }

    var showsCustomizeCard: Bool {
        !isCustomizeCardClosed
    }

    var startsWithAmountTitle: String {
        startsWithAmount ? "する" : "しない"
    }

    var themeTitle: String {
        theme.title(in: customThemes)
    }

    func isDone(_ item: SetupItem) -> Bool {
        progress.map(item.isDone) ?? false
    }

    func run() async {
        await withDiscardingTaskGroup { group in
            group.addTask {
                await self.observeProgress()
            }

            group.addTask {
                await self.observeCardClosed()
            }

            group.addTask {
                await self.observeCustomizeCardClosed()
            }

            group.addTask {
                await self.observeEntryOpened()
            }

            group.addTask {
                await self.observeSettingsOpened()
            }

            group.addTask {
                await self.observeLaunchScreen()
            }

            group.addTask {
                await self.observeStartsWithAmount()
            }

            group.addTask {
                await self.observeTheme()
            }

            group.addTask {
                await self.observeCustomThemes()
            }
        }
    }

    func setStartsWithAmount(_ starts: Bool) async {
        startsWithAmount = starts

        await save(.entryStartsWithAmount, to: starts)
    }

    func markEntryOpened() async {
        guard !isEntryOpened else {
            return
        }

        isEntryOpened = true

        await save(.entryOpened, to: true)
    }

    func markSettingsOpened() async {
        guard !isSettingsOpened else {
            return
        }

        isSettingsOpened = true

        await save(.settingsOpened, to: true)
    }

    func closeCard() async {
        isCardClosed = true

        await save(.setupCardClosed, to: true)
    }

    func closeCustomizeCard() async {
        isCustomizeCardClosed = true

        await save(.customizeCardClosed, to: true)
    }
}

private extension SetupModel {
    static let loadFailedMessage = "設定を読めませんでした"
    static let saveFailedMessage = "設定を保存できませんでした"

    func observeProgress() async {
        await observe(
            database.setupProgressUpdates(),
            failure: Self.loadFailedMessage
        ) { progress in
            self.progress = progress
        }
    }

    func observeCardClosed() async {
        await observe(
            database.settingUpdates(.setupCardClosed),
            failure: Self.loadFailedMessage
        ) { isClosed in
            isCardClosed = isClosed
        }
    }

    func observeCustomizeCardClosed() async {
        await observe(
            database.settingUpdates(.customizeCardClosed),
            failure: Self.loadFailedMessage
        ) { isClosed in
            isCustomizeCardClosed = isClosed
        }
    }

    func observeEntryOpened() async {
        await observe(
            database.settingUpdates(.entryOpened),
            failure: Self.loadFailedMessage
        ) { isOpened in
            isEntryOpened = isOpened
        }
    }

    func observeSettingsOpened() async {
        await observe(
            database.settingUpdates(.settingsOpened),
            failure: Self.loadFailedMessage
        ) { isOpened in
            isSettingsOpened = isOpened
        }
    }

    func observeLaunchScreen() async {
        await observe(
            database.settingUpdates(.launchScreen),
            failure: Self.loadFailedMessage
        ) { screen in
            launchScreen = screen
        }
    }

    func observeStartsWithAmount() async {
        await observe(
            database.settingUpdates(.entryStartsWithAmount),
            failure: Self.loadFailedMessage
        ) { starts in
            startsWithAmount = starts
        }
    }

    func observeTheme() async {
        await observe(
            database.settingUpdates(.theme),
            failure: Self.loadFailedMessage
        ) { theme in
            self.theme = theme
        }
    }

    func observeCustomThemes() async {
        await observe(
            database.customThemeUpdates(),
            failure: Self.loadFailedMessage
        ) { themes in
            customThemes = themes
        }
    }

    func save(
        _ key: SettingKey<Bool>,
        to value: Bool
    ) async {
        do {
            try await database.setSetting(key, to: value)
        } catch {
            errorNotice.show(Self.saveFailedMessage)
        }
    }
}
