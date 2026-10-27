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
        #expect(Percent.floor(part, of: whole) == expected)
    }
}
