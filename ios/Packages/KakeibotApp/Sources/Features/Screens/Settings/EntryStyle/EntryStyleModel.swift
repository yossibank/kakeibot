import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class EntryStyleModel {
    public private(set) var style: EntryStyle = .dial

    public internal(set) var errorNotice = ErrorNotice()

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension EntryStyleModel {
    func load() async {
        do {
            style = try await database.setting(.entryStyle)
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func choose(_ style: EntryStyle) async {
        guard style.isReady else {
            return
        }

        let previous = self.style
        self.style = style

        do {
            try await database.setSetting(.entryStyle, to: style)
        } catch {
            self.style = previous
            errorNotice.show(Self.saveFailedMessage)
        }
    }
}

private extension EntryStyleModel {
    static let loadFailedMessage = "設定を読めませんでした"
    static let saveFailedMessage = "設定を保存できませんでした"
}
