public struct LoanPayoff: Hashable, Sendable {
    public let count: Int
    public let lastDate: LocalDate

    public init(
        count: Int,
        lastDate: LocalDate
    ) {
        self.count = count
        self.lastDate = lastDate
    }
}

public extension LoanPayoff {
    init?(
        balance: Int,
        repayments: [Recurring],
        after today: LocalDate
    ) {
        let repayments = repayments.filter { $0.amount > 0 }
        var remaining = -balance

        guard remaining > 0, !repayments.isEmpty else {
            return nil
        }

        var count = 0
        var start = today.adding(days: 1)

        for _ in 0..<Self.searchYears {
            let end = start.adding(days: Self.daysPerSearch)

            let payments = repayments
                .flatMap { recurring in
                    recurring.dates(from: start, through: end)
                        .map { Payment(date: $0, amount: recurring.amount) }
                }
                .sorted { $0.date < $1.date }

            for payment in payments {
                remaining -= payment.amount
                count += 1

                if remaining <= 0 {
                    self.init(count: count, lastDate: payment.date)

                    return
                }
            }

            start = end.adding(days: 1)
        }

        return nil
    }
}

private extension LoanPayoff {
    struct Payment {
        let date: LocalDate
        let amount: Int
    }

    static let searchYears = 100
    static let daysPerSearch = 365
}
