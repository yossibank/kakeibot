import Core
import Foundation
import Store

public extension RecordsModel {
    struct ListDay: Identifiable, Hashable {
        public let date: LocalDate
        public let day: EntryDay?

        public var id: LocalDate {
            date
        }
    }

    var listDays: [ListDay] {
        let recorded = days.map { day in
            ListDay(date: day.date, day: day)
        }

        let recordedDates = Set(days.map(\.date))

        let planned = upcomingDates
            .filter { !recordedDates.contains($0) }
            .map { date in
                ListDay(date: date, day: nil)
            }

        return (recorded + planned).sorted { $0.date > $1.date }
    }

    var upcomingDates: [LocalDate] {
        let start = max(period.lowerBound, today.adding(days: 1))

        guard
            filterTitle == nil,
            start <= period.upperBound
        else {
            return []
        }

        let dates = recurrings.flatMap { recurring in
            recurring.dates(from: start, through: period.upperBound)
        }

        return Set(dates).sorted()
    }

    func listCaptions(in days: [ListDay]) -> [LocalDate: String] {
        guard let firstFuture = days.first(where: { $0.date > today }) else {
            return [:]
        }

        var captions = [firstFuture.date: Self.futureCaption]

        if let firstPast = days.first(where: { $0.date <= today }) {
            captions[firstPast.date] = Self.pastCaption
        }

        return captions
    }

    func listRecurrings(on date: LocalDate) -> [Recurring] {
        guard
            filterTitle == nil,
            !isSearching
        else {
            return []
        }

        return upcomingRecurrings(on: date)
    }

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
        list?.amount(of: recurring, on: date) ?? recurring.scheduledAmount(paidOn: date)
    }

    func title(of recurring: Recurring) -> String {
        list?.title(of: recurring) ?? Self.recurringTitle
    }
}

private extension RecordsModel {
    static let recurringTitle = "固定費"
    static let futureCaption = "これから"
    static let pastCaption = "これまで"
}
