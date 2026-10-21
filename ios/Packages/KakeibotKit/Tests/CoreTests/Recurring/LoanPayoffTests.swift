import Core
import Foundation
import Testing

struct LoanPayoffTests {
    @Test(arguments: try payoffCases)
    func findsLastRepayment(fixture: PayoffCase) throws {
        let loan = Wallet.ID()
        let repayments = try fixture.repayments
            .map { try $0.recurring(to: loan) }

        let payoff = LoanPayoff(
            balance: fixture.balance,
            repayments: repayments,
            after: fixture.today
        )

        #expect(payoff?.count == fixture.count)
        #expect(payoff?.lastDate == fixture.lastDate)
    }
}

extension LoanPayoffTests {
    struct PayoffCase: Decodable, Sendable {
        let balance: Int
        let today: LocalDate
        let repayments: [RepaymentCase]
        let count: Int?
        let lastDate: LocalDate?
    }

    struct RepaymentCase: Decodable, Sendable {
        let amount: Int
        let day: Int
        let endDate: LocalDate?
    }
}

extension LoanPayoffTests.RepaymentCase {
    func recurring(to loan: Wallet.ID) throws -> Recurring {
        let now = Date(timeIntervalSince1970: 1_791_000_000)

        return try Recurring(
            type: .transfer,
            amount: amount,
            categoryId: nil,
            walletId: Wallet.ID(),
            toWalletId: loan,
            frequency: .monthly,
            day: day,
            startDate: #require(LocalDate("2026-01-01")),
            endDate: endDate,
            createdAt: now,
            updatedAt: now
        )
    }
}

private extension LoanPayoffTests {
    static var payoffCases: [PayoffCase] {
        get throws {
            try Fixture.load("recurring/loan-payoff.json")
        }
    }
}
