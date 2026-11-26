import Core
import Store

public extension HomeModel.Output {
    var stampTallies: [StampBook.Tally] {
        input.stampBook?.tallies(in: period) ?? []
    }

    func stampDays(of tally: StampBook.Tally) -> [LocalDate] {
        input.stampBook?.days(of: tally, in: period) ?? []
    }

    func day(on date: LocalDate) -> EntryDay? {
        input.list.value?.days.first { $0.date == date }
    }
}
