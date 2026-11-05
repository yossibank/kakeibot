import Core
import Foundation
import Testing

struct RecurringFinalAmountTests {
    @Test(arguments: try finalCases)
    func findsEndDateFromCount(fixture: FinalCase) {
        let recurring = fixture.recurring(endDate: nil)

        #expect(recurring.endDate(afterCount: fixture.count) == fixture.endDate)
    }

    @Test(arguments: try finalCases)
    func countsOccurrences(fixture: FinalCase) {
        let recurring = fixture.recurring(endDate: fixture.endDate)

        #expect(recurring.occurrenceCount == fixture.count)
    }

    @Test(arguments: try finalCases)
    func addsUpPlannedTotal(fixture: FinalCase) {
        let recurring = fixture.recurring(endDate: fixture.endDate)

        #expect(recurring.plannedTotal == fixture.total)
    }

    @Test(arguments: try finalCases)
    func limitsCount(fixture: FinalCase) {
        let recurring = fixture.recurring(endDate: nil)

        #expect(recurring.endDate(afterCount: Recurring.maxCount) != nil)
        #expect(recurring.endDate(afterCount: Recurring.maxCount + 1) == nil)
    }
}

extension RecurringFinalAmountTests {
    struct FinalCase: Decodable, Sendable, CustomTestStringConvertible {
        let summary: String
        let amount: Int
        let finalAmount: Int?
        let day: Int
        let startDate: LocalDate
        let count: Int
        let endDate: LocalDate
        let total: Int

        var testDescription: String {
            summary
        }
    }
}

extension RecurringFinalAmountTests.FinalCase {
    func recurring(endDate: LocalDate?) -> Recurring {
        let now = Date(timeIntervalSince1970: 1_791_000_000)

        return Recurring(
            type: .transfer,
            amount: amount,
            categoryId: nil,
            walletId: Wallet.ID(),
            toWalletId: Wallet.ID(),
            frequency: .monthly,
            day: day,
            finalAmount: finalAmount,
            startDate: startDate,
            endDate: endDate,
            createdAt: now,
            updatedAt: now
        )
    }
}

private extension RecurringFinalAmountTests {
    static var finalCases: [FinalCase] {
        get throws {
            try CoreFixture.cases("recurring/final-amount.json")
        }
    }
}
