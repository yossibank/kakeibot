import Core
import Testing

struct PercentTests {
    @Test(arguments: [
        (290_000, 1_000_000, 29),
        (999, 1000, 99),
        (0, 1000, 0),
        (1000, 1000, 100),
        (2000, 1000, 100),
        (-500, 1000, 0),
        (500, 0, 0),
        (500, -1, 0)
    ])
    func floorsToWholePercent(part: Int, whole: Int, expected: Int) {
        let percent = Percent.floor(part, of: whole)
        #expect(percent == expected)
    }

    @Test(arguments: [
        ([42400, 36400, 21200], [43, 36, 21]),
        ([30000, 50000], [38, 62]),
        ([1, 1, 1], [34, 33, 33]),
        ([20, 30, 50], [20, 30, 50]),
        ([100], [100]),
        ([0, 0], [0, 0])
    ])
    func sharesAddUpToHundred(parts: [Int], expected: [Int]) {
        #expect(Percent.shares(parts) == expected)
    }
}
