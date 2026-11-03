import Core
import Foundation
import Store

public extension RecordsModel {
    var stampChoices: [Icon] {
        guard let stampShelf else {
            return []
        }

        return stampShelf.shelfIcons
            .filter { $0.archivedAt == nil }
            .compactMap { stampShelf.icons[$0.iconId] }
    }

    func stampIcon(on date: LocalDate) -> Icon? {
        stampCalendar?.icon(on: date)
    }

    func stamp(
        _ icon: Icon,
        on date: LocalDate
    ) async {
        do {
            try await database.stamp(icon.id, on: date, at: Date())
        } catch {
            errorNotice.show(Self.saveFailedMessage, for: error)
        }
    }

    func removeStamp(on date: LocalDate) async {
        do {
            try await database.removeStamp(on: date)
        } catch {
            errorNotice.show(Self.saveFailedMessage, for: error)
        }
    }

    func stampEditModel() -> StampEditModel {
        StampEditModel(database: database)
    }

    func canMarkNoSpend(on date: LocalDate) -> Bool {
        date <= today && (day(on: date)?.expenseTotal ?? 0) == 0
    }

    func toggleNoSpendDay(on date: LocalDate) async {
        do {
            if noSpendDays.contains(date) {
                try await database.unmarkNoSpendDay(date)
            } else {
                try await database.markNoSpendDay(date, at: Date())
            }
        } catch {
            errorNotice.show(Self.saveFailedMessage, for: error)
        }
    }
}
