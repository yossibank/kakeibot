public extension ClosedRange<LocalDate> {
    func weeks(startingOn weekStart: Weekday) -> [[LocalDate?]] {
        let firstOffset = lowerBound.weekday.daysSinceMonday
        let difference = firstOffset - weekStart.daysSinceMonday
        let leading = (difference + 7) % 7
        let count = upperBound.dayNumber - lowerBound.dayNumber + 1
        let days = (0..<count).map { lowerBound.adding(days: $0) }
        let filled = Array(repeating: nil, count: leading) + days
        let trailing = (7 - filled.count % 7) % 7
        let cells = filled + Array(repeating: nil, count: trailing)

        return stride(from: 0, to: cells.count, by: 7).map { start in
            Array(cells[start..<start + 7])
        }
    }
}
