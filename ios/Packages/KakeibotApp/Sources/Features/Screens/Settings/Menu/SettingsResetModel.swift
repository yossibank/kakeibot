import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class SettingsResetModel {
    public private(set) var count = 0
    public private(set) var hasSharedWallets = false

    public internal(set) var errorNotice = ErrorNotice()

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension SettingsResetModel {
    func prepare() async -> Bool {
        do {
            count = try await database.deletableRecordCount()
            hasSharedWallets = try await sharesWallets()
        } catch {
            errorNotice.show(Self.loadFailedMessage, for: error)

            return false
        }

        if count == 0 {
            errorNotice.inform(Self.emptyMessage)
        }

        return count > 0
    }

    func deleteAll() async {
        do {
            try await database.deleteAllRecords()
            errorNotice.inform(Self.deletedMessage)
        } catch {
            errorNotice.show(Self.deleteFailedMessage, for: error)
        }
    }

    func message(isSyncing: Bool) -> String {
        let amount = count.formatted(.number)
        var text = "記録・評価額・スタンプなど\(amount)件を削除します。口座・カテゴリ・設定は残ります。元に戻せません。"

        if isSyncing {
            text += "ほかの iPhone からも消えます。"
        }

        if hasSharedWallets {
            text += "共有中の口座の記録は残ります。"
        }

        return text
    }
}

private extension SettingsResetModel {
    static let emptyMessage = "削除する記録はありません"
    static let deletedMessage = "記録をすべて削除しました"
    static let loadFailedMessage = "記録の件数を読み込めませんでした"
    static let deleteFailedMessage = "記録を削除できませんでした"

    func sharesWallets() async throws -> Bool {
        for try await shares in database.walletShareUpdates() {
            if shares.contains(where: \.isShared) {
                return true
            }

            break
        }

        for try await joined in database.joinedShareUpdates() {
            return !joined.isEmpty
        }

        return false
    }
}
