import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class EntryStartModel {
    public private(set) var startsWithAmount = true
    public private(set) var isLoaded = false

    public internal(set) var errorNotice = ErrorNotice()

    public let database: AppDatabase
    public let today: LocalDate

    public init(
        database: AppDatabase,
        today: LocalDate
    ) {
        self.database = database
        self.today = today
    }
}

public extension EntryStartModel {
    func load() async {
        do {
            startsWithAmount = try await database.setting(.entryStartsWithAmount)
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }

        isLoaded = true
    }

    func choose(_ starts: Bool) async {
        let previous = startsWithAmount

        startsWithAmount = starts

        do {
            try await database.setSetting(.entryStartsWithAmount, to: starts)
        } catch {
            startsWithAmount = previous
            errorNotice.show(Self.saveFailedMessage)
        }
    }
}

private extension EntryStartModel {
    static let loadFailedMessage = "設定を読めませんでした"
    static let saveFailedMessage = "設定を保存できませんでした"
}
