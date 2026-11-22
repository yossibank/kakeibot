public extension ReviewGoal {
    struct Progress: Hashable, Sendable {
        public let count: Int
        public let amount: Int
        public let projectedCount: Int

        public init(
            count: Int,
            amount: Int,
            projectedCount: Int
        ) {
            self.count = count
            self.amount = amount
            self.projectedCount = projectedCount
        }
    }

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
            projectedCount: pace.projected
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

    func isOnTrack(_ progress: Progress) -> Bool {
        switch kind {
        case .count:
            progress.projectedCount <= target

        case .average:
            current(of: progress) <= target
        }
    }
}
