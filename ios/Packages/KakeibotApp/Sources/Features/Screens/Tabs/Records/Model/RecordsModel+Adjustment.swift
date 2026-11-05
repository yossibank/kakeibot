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

    func adjustmentRows(on date: LocalDate) -> [AdjustmentRow] {
        guard
            showsAdjustments,
            let list
        else {
            return []
        }

        return list.adjustments
            .filter { $0.date == date }
            .sorted { $0.createdAt > $1.createdAt }
            .map { adjustment in
                AdjustmentRow(
                    adjustment: adjustment,
                    walletName: list.wallets[adjustment.walletId]?.name ?? Self.walletFallback
                )
            }
    }

    func deleteAdjustment(_ id: Adjustment.ID) async -> Deletion? {
        do {
            return try await database.deleteAdjustment(id)
        } catch {
            errorNotice.show(Self.deleteAdjustmentFailedMessage, for: error)
            return nil
        }
    }
}

public extension RecordsModel.AdjustmentRow {
    var amountText: String {
        let sign = adjustment.amount > 0 ? "+" : ""
        return sign + AmountText.text(adjustment.amount)
    }
}

extension RecordsModel {
    func adjustedDays(besides days: [EntryDay]) -> [EntryDay] {
        guard
            showsAdjustments,
            let list
        else {
            return []
        }

        let recorded = Set(days.map(\.date))

        let dates = Set(list.adjustments.map(\.date))
            .filter { period.contains($0) && !recorded.contains($0) }

        return dates.map { EntryDay(date: $0, entries: []) }
    }
}

private extension RecordsModel {
    static let walletFallback = "口座"
    static let deleteAdjustmentFailedMessage = "残高の調整を削除できませんでした"

    var showsAdjustments: Bool {
        filter.isEmpty && !isSearching
    }
}
