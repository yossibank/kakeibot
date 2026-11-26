public extension ReviewGoal {
    struct Progress: Hashable, Sendable {
        public let count: Int
        public let amount: Int
        public let projectedCount: Int
        public let elapsedRatio: Double

        public init(
            count: Int,
            amount: Int,
            projectedCount: Int,
            elapsedRatio: Double
        ) {
            self.count = count
            self.amount = amount
            self.projectedCount = projectedCount
            self.elapsedRatio = elapsedRatio
        }
    }

    enum Status: Hashable, Sendable {
        case within
        case likelyOver
        case over
    }
}

public extension ReviewGoal {
    func progress(
        of entries: [Entry],
        in range: ClosedRange<LocalDate>,
        today: LocalDate
    ) -> Progress {
        let memo = Self.normalizedMemo(memo)

        let matched = entries.filter { entry in
            entry.type == .expense
                && range.contains(entry.date)
                && entry.date <= today
                && entry.categoryId == categoryId
                && (memo == nil || Self.normalizedMemo(entry.memo) == memo)
        }

        let pace = ReviewPace(
            limit: target,
            basis: .budget,
            spent: matched.count,
            range: range,
            today: today
        )

        return Progress(
            count: matched.count,
            amount: matched.reduce(0) { $0 + $1.amount },
            projectedCount: pace.projected,
            elapsedRatio: pace.elapsedRatio
        )
    }

    func current(of progress: Progress) -> Int {
        switch kind {
        case .count:
            progress.count

        case .average:
            progress.count > 0 ? progress.amount / progress.count : 0
        }
    }

    func status(of progress: Progress) -> Status? {
        let isOver = kind == .count
            && progress.count > target

        let isWithin = switch kind {
        case .count: progress.projectedCount <= target
        case .average: current(of: progress) <= target
        }

        if isOver {
            return .over
        }

        if isWithin {
            return .within
        }

        return progress.elapsedRatio < Self.settledRatio ? nil : .likelyOver
    }
}

private extension ReviewGoal {
    static let settledRatio = 0.3
}
