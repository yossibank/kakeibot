import Core
import DesignSystem
import Store

public extension RecordsModel {
    struct AdjustmentRow: Equatable, Identifiable {
        public let adjustment: Adjustment
        public let walletName: String

        public var id: Adjustment.ID {
            adjustment.id
        }
    }

    func deleteAdjustment(_ id: Adjustment.ID) async -> Deletion? {
        do {
            return try await dependencies.database.deleteAdjustment(id)
        } catch {
            state.errorNotice.show(Self.deleteAdjustmentFailedMessage, for: error)
            return nil
        }
    }
}

private extension RecordsModel {
    static let deleteAdjustmentFailedMessage = "残高の調整を削除できませんでした"
}
