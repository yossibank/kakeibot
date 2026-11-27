import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class SettingsMenuResetModel: ScreenPerforming {
    public let state: State
    public let input: Input
    public let output: Output

    let dependencies: ScreenParts

    public init(parts: ScreenParts) {
        let input = Input()

        self.state = State(wait: parts.wait)
        self.input = input
        self.output = Output(input: input)
        self.dependencies = parts
    }
}

public extension SettingsMenuResetModel {
    enum Prompt: Hashable, Sendable {
        case deleteAll
    }

    @MainActor
    @Observable
    final class State: NoticeHolding {
        public var prompt = Shown<Prompt>()

        public let errorNotice: ErrorNotice
        public let task = ModelTask()

        init(wait: ScreenWait) {
            self.errorNotice = ErrorNotice(wait: wait)
        }
    }

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
}

public extension SettingsMenuResetModel {
    @discardableResult
    func prepare() async -> Bool {
        guard !state.task.isRunning else {
            return false
        }

        do {
            try await state.task.attempt {
                input.count = try await dependencies.database.deletableRecordCount()
                input.hasSharedWallets = try await sharesWallets()
            }
        } catch {
            state.errorNotice.show(Self.loadFailedMessage, for: error)
            state.prompt.close(.deleteAll)
            return false
        }

        guard input.count > 0 else {
            state.errorNotice.inform(Self.emptyMessage)
            state.prompt.close(.deleteAll)
            return false
        }

        state.prompt.show(.deleteAll)

        return true
    }

    func deleteAll() async {
        guard !state.task.isRunning else {
            return
        }

        do {
            try await state.task.attempt {
                try await dependencies.database.deleteAllRecords(at: dependencies.clock.now)
            }

            state.errorNotice.inform(Self.deletedMessage)
        } catch {
            state.errorNotice.show(Self.deleteFailedMessage, for: error)
        }
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
