import Core
import Store

public extension RecordsModel.Output {
    var stampChoices: [Icon] {
        guard let stampShelf = input.stampShelf else {
            return []
        }

        return stampShelf.shelfIcons
            .filter { $0.archivedAt == nil }
            .compactMap { stampShelf.icons[$0.iconId] }
    }

    func stampIcon(on date: LocalDate) -> Icon? {
        input.stampBook?.icon(on: date)
    }

    func canMarkNoSpend(on date: LocalDate) -> Bool {
        date <= input.today && (day(on: date)?.expenseTotal ?? 0) == 0
    }
}
