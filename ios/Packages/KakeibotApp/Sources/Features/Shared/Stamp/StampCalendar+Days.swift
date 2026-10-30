import Core
import Store

extension StampCalendar {
    func days(
        of tally: Tally,
        in range: ClosedRange<LocalDate>
    ) -> [LocalDate] {
        stamps.values
            .filter { $0.iconId == tally.icon.id }
            .map(\.date)
            .filter { range.contains($0) }
            .sorted(by: >)
    }
}
