public enum Percent {
    public static func floor(
        _ part: Int,
        of whole: Int
    ) -> Int {
        guard whole > 0 else {
            return 0
        }

        let percent = part * 100 / whole
        let nonNegative = max(percent, 0)

        return min(nonNegative, 100)
    }

    public static func shares(_ parts: [Int]) -> [Int] {
        let whole = parts.reduce(0, +)

        guard whole > 0 else {
            return parts.map { _ in 0 }
        }

        var percents = parts.map { $0 * 100 / whole }

        let rest = 100 - percents.reduce(0, +)

        let order = parts.indices.sorted { lhs, rhs in
            let lhsRest = parts[lhs] * 100 % whole
            let rhsRest = parts[rhs] * 100 % whole

            return lhsRest == rhsRest ? lhs < rhs : lhsRest > rhsRest
        }

        for index in order.prefix(rest) {
            percents[index] += 1
        }

        return percents
    }
}
