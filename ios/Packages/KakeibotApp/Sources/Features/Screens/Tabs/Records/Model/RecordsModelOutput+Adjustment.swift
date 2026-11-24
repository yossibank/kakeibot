import Core
import DesignSystem
import Store

public extension RecordsModel.Output {
    func adjustmentRows(on date: LocalDate) -> [RecordsModel.AdjustmentRow] {
        guard
            showsAdjustments,
            let list = input.list
        else {
            return []
        }

        return list.adjustments
            .filter { $0.date == date }
            .sorted { $0.createdAt > $1.createdAt }
            .map { adjustment in
                RecordsModel.AdjustmentRow(
                    adjustment: adjustment,
                    walletName: list.wallets[adjustment.walletId]?.name ?? Self.walletFallback
                )
            }
    }
}

extension RecordsModel.Output {
    func adjustedDays(besides days: [EntryDay]) -> [EntryDay] {
        guard
            showsAdjustments,
            let list = input.list
        else {
            return []
        }

        let recorded = Set(days.map(\.date))

        let dates = Set(list.adjustments.map(\.date))
            .filter { period.contains($0) && !recorded.contains($0) }

        return dates.map { EntryDay(date: $0, entries: []) }
    }
}

private extension RecordsModel.Output {
    static let walletFallback = "口座"

    var showsAdjustments: Bool {
        state.filter.isEmpty && !state.isSearching
    }
}
