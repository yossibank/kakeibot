import Core
import Store

extension HomeModel {
    var stampTallies: [StampBook.Tally] {
        stampBook?.tallies(in: period) ?? []
    }

    func stampDays(of tally: StampBook.Tally) -> [LocalDate] {
        stampBook?.days(of: tally, in: period) ?? []
    }

    func day(on date: LocalDate) -> EntryDay? {
        list?.days.first { $0.date == date }
    }
}
