import Core
import DesignSystem
import Store

public extension RecordsModel {
    struct AdjustmentRow: Equatable, Identifiable {
        public let adjustment: Adjustment
        public let walletName: String
    }
}

public extension RecordsModel {
    @discardableResult
    func deleteAdjustment(_ id: Adjustment.ID) async -> Deletion? {
        do {
            let deletion = try await dependencies.database.deleteAdjustment(id)

            if let deletion {
                state.outcome.send(deletion)
            }

            return deletion
        } catch {
            state.errorNotice.show(Self.deleteAdjustmentFailedMessage, for: error)
            return nil
        }
    }
}

private extension RecordsModel {
    static let deleteAdjustmentFailedMessage = "残高の調整を削除できませんでした"
}

public extension RecordsModel.AdjustmentRow {
    var id: Adjustment.ID {
        adjustment.id
    }
}
