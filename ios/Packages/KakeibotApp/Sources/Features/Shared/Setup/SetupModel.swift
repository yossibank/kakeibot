import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class SetupModel: ScreenModel {
    public let state = NoticeState()
    public let input: Input
    public let output: Output

    let dependencies: Dependencies

    public init(
        database: AppDatabase,
        newsVersion: String
    ) {
        let input = Input(newsVersion: newsVersion)

        self.input = input
        self.output = Output(input: input)
        self.dependencies = Dependencies(database: database)
    }
}

public extension SetupModel {
    @MainActor
    @Observable
    final class Input {
        public internal(set) var progress: SetupProgress?
        public internal(set) var isEntryOpened = true
        public internal(set) var launchScreen: LaunchScreen = .home
        public internal(set) var theme: ThemeChoice = .system
        public internal(set) var customThemes: [Theme] = []

        var cardClosed: Bool?
        var seenNews: Loadable<String?> = .loading

        let newsVersion: String

        init(newsVersion: String) {
            self.newsVersion = newsVersion
        }
    }

    @MainActor
    final class Output {
        let input: Input

        init(input: Input) {
            self.input = input
        }
    }

    func run() async {
        let database = dependencies.database

        await observeAll([
            {
                await self.observe(database.setupProgressUpdates(), into: \.input.progress)
            },
            {
                await self.observe(
                    database.settingUpdates(.setupCardClosed),
                    into: \.input.cardClosed
                )
            },
            {
                await self.observe(
                    database.settingUpdates(.entryOpened),
                    into: \.input.isEntryOpened
                )
            },
            {
                await self.observe(
                    database.settingUpdates(.launchScreen),
                    into: \.input.launchScreen
                )
            },
            {
                await self.observe(database.settingUpdates(.theme), into: \.input.theme)
            },
            {
                await self.observe(database.customThemeUpdates(), into: \.input.customThemes)
            },
            {
                await self.observeSeenNews()
            }
        ])
    }

    func markNewsSeen() async {
        let version = input.newsVersion

        guard AppVersion.isNewer(version, than: output.seenNewsVersion) else {
            return
        }

        input.seenNews = .loaded(version)

        do {
            try await dependencies.database.setSetting(.whatsNewSeenVersion, to: version)
        } catch {
            state.errorNotice.show(Self.saveFailedMessage, for: error)
        }
    }

    func markEntryOpened() async {
        guard !input.isEntryOpened else {
            return
        }

        input.isEntryOpened = true

        await save(.entryOpened, to: true)
    }

    func closeCard() async {
        input.cardClosed = true
        await save(.setupCardClosed, to: true)
    }
}

public extension SetupModel.Output {
    var cardItems: [SetupItem] {
        guard let progress = input.progress else {
            return []
        }

        return SetupItem.home.filter { !$0.isDone(in: progress) }
    }

    var isCardClosed: Bool {
        input.cardClosed ?? true
    }

    var seenNewsVersion: String? {
        input.seenNews.value ?? nil
    }

    var isLoaded: Bool {
        input.progress != nil && input.cardClosed != nil
    }

    var showsCard: Bool {
        !isCardClosed && !cardItems.isEmpty
    }

    var themeTitle: String {
        input.theme.title(in: input.customThemes)
    }

    var hasUnreadNews: Bool {
        input.seenNews.isLoaded && AppVersion.isNewer(
            input.newsVersion,
            than: seenNewsVersion
        )
    }

    func isDone(_ item: SetupItem) -> Bool {
        input.progress.map(item.isDone) ?? false
    }
}

extension SetupModel {
    struct Dependencies {
        let database: AppDatabase
    }

    static let loadFailedMessage = "設定を読めませんでした"
}

private extension SetupModel {
    static let saveFailedMessage = "設定を保存できませんでした"

    func observeSeenNews() async {
        await observe(
            dependencies.database.settingUpdates(.whatsNewSeenVersion),
            failure: Self.loadFailedMessage
        ) { version in
            input.seenNews = .loaded(version)
        }
    }

    func save(
        _ key: SettingKey<Bool>,
        to value: Bool
    ) async {
        do {
            try await dependencies.database.setSetting(key, to: value)
        } catch {
            state.errorNotice.show(Self.saveFailedMessage, for: error)
        }
    }
}
