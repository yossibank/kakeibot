import Core

extension ReviewPeriod {
    var displayName: String {
        let start = range.lowerBound
        let month = range.upperBound.yearMonth

        return switch scale {
        case .week: "\(start.monthDayText) の週"
        case .month: "\(month.month)月"
        case .year: "\(String(month.year))年"
        }
    }
}
