import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class SetupModel: ScreenModel {
    public private(set) var progress: SetupProgress?
    public private(set) var isCardClosed = true
    public private(set) var isEntryOpened = true
    public private(set) var launchScreen: LaunchScreen = .home
    public private(set) var theme: ThemeChoice = .system
    public private(set) var customThemes: [Theme] = []
    public private(set) var seenNewsVersion: String?

    public internal(set) var errorNotice = ErrorNotice()

    private var isCardClosedLoaded = false
    private var isNewsLoaded = false

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

    var isLoaded: Bool {
        progress != nil && isCardClosedLoaded
    }

    var showsCard: Bool {
        !isCardClosed && !cardItems.isEmpty
    }

    var themeTitle: String {
        theme.title(in: customThemes)
    }

    var hasUnreadNews: Bool {
        isNewsLoaded && AppVersion.isNewer(WhatsNewRelease.latestVersion, than: seenNewsVersion)
    }

    func isDone(_ item: SetupItem) -> Bool {
        progress.map(item.isDone) ?? false
    }

    func run() async {
        await observeAll([
            {
                await self.observe(self.database.setupProgressUpdates(), into: \.progress)
            },
            {
                await self.observeCardClosed()
            },
            {
                await self.observe(
                    self.database.settingUpdates(.entryOpened),
                    into: \.isEntryOpened
                )
            },
            {
                await self.observe(
                    self.database.settingUpdates(.launchScreen),
                    into: \.launchScreen
                )
            },
            {
                await self.observe(self.database.settingUpdates(.theme), into: \.theme)
            },
            {
                await self.observe(self.database.customThemeUpdates(), into: \.customThemes)
            },
            {
                await self.observeSeenNews()
            }
        ])
    }

    func markNewsSeen() async {
        let version = WhatsNewRelease.latestVersion

        guard AppVersion.isNewer(version, than: seenNewsVersion) else {
            return
        }

        seenNewsVersion = version

        do {
            try await database.setSetting(.whatsNewSeenVersion, to: version)
        } catch {
            errorNotice.show(Self.saveFailedMessage, for: error)
        }
    }

    func markEntryOpened() async {
        guard !isEntryOpened else {
            return
        }

        isEntryOpened = true

        await save(.entryOpened, to: true)
    }

    func closeCard() async {
        isCardClosed = true
        await save(.setupCardClosed, to: true)
    }
}

extension SetupModel {
    static let loadFailedMessage = "設定を読めませんでした"
}

private extension SetupModel {
    static let saveFailedMessage = "設定を保存できませんでした"

    func observeCardClosed() async {
        await observe(
            database.settingUpdates(.setupCardClosed),
            failure: Self.loadFailedMessage
        ) { isClosed in
            isCardClosed = isClosed
            isCardClosedLoaded = true
        }
    }

    func observeSeenNews() async {
        await observe(
            database.settingUpdates(.whatsNewSeenVersion),
            failure: Self.loadFailedMessage
        ) { version in
            seenNewsVersion = version
            isNewsLoaded = true
        }
    }

    func save(
        _ key: SettingKey<Bool>,
        to value: Bool
    ) async {
        do {
            try await database.setSetting(key, to: value)
        } catch {
            errorNotice.show(Self.saveFailedMessage, for: error)
        }
    }
}
