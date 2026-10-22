import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class LaunchScreenModel {
    public private(set) var screen: LaunchScreen = .entry

    public internal(set) var errorNotice = ErrorNotice()

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension LaunchScreenModel {
    func load() async {
        do {
            screen = try await database.setting(.launchScreen)
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func choose(_ screen: LaunchScreen) async {
        let previous = self.screen
        self.screen = screen

        do {
            try await database.setSetting(.launchScreen, to: screen)
        } catch {
            self.screen = previous
            errorNotice.show(Self.saveFailedMessage)
        }
    }
}

private extension LaunchScreenModel {
    static let loadFailedMessage = "設定を読めませんでした"
    static let saveFailedMessage = "設定を保存できませんでした"
}
