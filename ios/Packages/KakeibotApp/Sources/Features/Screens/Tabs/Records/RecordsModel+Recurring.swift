import Core
import Foundation
import Store

public extension RecordsModel {
    func upcomingRecurrings(on date: LocalDate) -> [Recurring] {
        guard date > today else {
            return []
        }

        return recurrings.filter { recurring in
            !recurring.dates(from: date, through: date).isEmpty
        }
    }

    func amount(
        of recurring: Recurring,
        on date: LocalDate
    ) -> Int {
        list?.amount(of: recurring, on: date) ?? recurring.amount
    }

    func title(of recurring: Recurring) -> String {
        list?.title(of: recurring) ?? Self.recurringTitle
    }
}

private extension RecordsModel {
    static let recurringTitle = "固定費"
}
