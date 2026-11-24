import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class SettingsMenuResetModel {
    public let state = NoticeState()
    public let input: Input
    public let output: Output

    let dependencies: Dependencies

    public init(
        database: AppDatabase,
        clock: ScreenClock
    ) {
        let input = Input()

        self.input = input
        self.output = Output(input: input)
        self.dependencies = Dependencies(database: database, clock: clock)
    }
}

public extension SettingsMenuResetModel {
    @MainActor
    @Observable
    final class Input {
        public internal(set) var count = 0
        public internal(set) var hasSharedWallets = false
    }

    @MainActor
    final class Output {
        let input: Input

        init(input: Input) {
            self.input = input
        }
    }

    func prepare() async -> Bool {
        do {
            input.count = try await dependencies.database.deletableRecordCount()
            input.hasSharedWallets = try await sharesWallets()
        } catch {
            state.errorNotice.show(Self.loadFailedMessage, for: error)

            return false
        }

        if input.count == 0 {
            state.errorNotice.inform(Self.emptyMessage)
        }

        return input.count > 0
    }

    func deleteAll() async {
        do {
            try await dependencies.database.deleteAllRecords(at: dependencies.clock.now)
            state.errorNotice.inform(Self.deletedMessage)
        } catch {
            state.errorNotice.show(Self.deleteFailedMessage, for: error)
        }
    }
}

public extension SettingsMenuResetModel.Output {
    func message(isSyncing: Bool) -> String {
        let amount = input.count.formatted(.number)
        var text = "記録・評価額・スタンプなど\(amount)件を削除します。口座・カテゴリ・設定は残ります。元に戻せません。"

        if isSyncing {
            text += "ほかの端末からも消えます。"
        }

        if input.hasSharedWallets {
            text += "共有中の口座の記録は残ります。"
        }

        return text
    }
}

extension SettingsMenuResetModel {
    struct Dependencies {
        let database: AppDatabase
        let clock: ScreenClock
    }
}

private extension SettingsMenuResetModel {
    static let emptyMessage = "削除する記録はありません"
    static let deletedMessage = "記録をすべて削除しました"
    static let loadFailedMessage = "記録の件数を読めませんでした"
    static let deleteFailedMessage = "記録を削除できませんでした"

    func sharesWallets() async throws -> Bool {
        for try await shares in dependencies.database.walletShareUpdates() {
            if shares.contains(where: \.isShared) {
                return true
            }

            break
        }

        for try await joined in dependencies.database.joinedShareUpdates() {
            return !joined.isEmpty
        }

        return false
    }
}
