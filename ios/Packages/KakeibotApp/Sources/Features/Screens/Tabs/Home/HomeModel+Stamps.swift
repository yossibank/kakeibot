import Core
import Store

extension HomeModel {
    var stampTallies: [StampCalendar.Tally] {
        stampCalendar?.tallies(in: period) ?? []
    }

    func stampDays(of tally: StampCalendar.Tally) -> [LocalDate] {
        stampCalendar?.days(of: tally, in: period) ?? []
    }

    func day(on date: LocalDate) -> EntryDay? {
        list?.days.first { $0.date == date }
    }
}
