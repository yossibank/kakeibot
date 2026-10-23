import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class SetupModel: ScreenModel {
    public private(set) var progress: SetupProgress?
    public private(set) var isCardClosed = true
    public private(set) var isEntryOpened = true
    public private(set) var isSettingsOpened = true

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
                await self.observeEntryOpened()
            }

            group.addTask {
                await self.observeSettingsOpened()
            }
        }
    }

    func markEntryOpened() async {
        guard !isEntryOpened else {
            return
        }

        isEntryOpened = true

        await save(.entryOpened)
    }

    func markSettingsOpened() async {
        guard !isSettingsOpened else {
            return
        }

        isSettingsOpened = true

        await save(.settingsOpened)
    }

    func closeCard() async {
        isCardClosed = true

        await save(.setupCardClosed)
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

    func save(_ key: SettingKey<Bool>) async {
        do {
            try await database.setSetting(key, to: true)
        } catch {
            errorNotice.show(Self.saveFailedMessage)
        }
    }
}
