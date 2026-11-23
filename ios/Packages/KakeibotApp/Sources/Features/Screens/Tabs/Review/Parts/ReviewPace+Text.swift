import Core

extension ReviewPace {
    static func percent(_ ratio: Double) -> Int {
        Int((ratio * 100).rounded())
    }

    static func periodsUnit(_ unit: String) -> String {
        unit == "月" ? "か月" : unit
    }

    func limitName(unit: String) -> String {
        switch basis {
        case .budget: "予算"
        case let .average(periods): "\(periods) \(Self.periodsUnit(unit))の平均"
        }
    }
}
