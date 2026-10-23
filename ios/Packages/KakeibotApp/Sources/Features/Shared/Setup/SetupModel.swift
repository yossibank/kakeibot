import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class SetupModel: ScreenModel {
    public private(set) var progress: SetupProgress?
    public private(set) var isCardClosed = true

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
        }
    }

    func closeCard() async {
        isCardClosed = true

        do {
            try await database.setSetting(.setupCardClosed, to: true)
        } catch {
            errorNotice.show(Self.saveFailedMessage)
        }
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
}
