import Core
import Foundation
import Testing

struct ReceiptFragmentTests {
    @Test(arguments: try fragmentCases)
    func groupsFragmentsIntoLines(fixture: FragmentCase) {
        let fragments = fixture.fragments.map(\.fragment)

        let lines = ReceiptFragment.lines(of: fragments)

        #expect(lines == fixture.lines)
    }
}

extension ReceiptFragmentTests {
    struct FragmentCase: Decodable, Sendable, CustomTestStringConvertible {
        let summary: String
        let fragments: [FragmentValue]
        let lines: [String]

        var testDescription: String {
            summary
        }
    }

    struct FragmentValue: Decodable, Sendable {
        let text: String
        let minX: Double
        let midY: Double
        let height: Double
        let maxX: Double?
        let tilt: Double?

        var fragment: ReceiptFragment {
            ReceiptFragment(
                text: text,
                minX: minX,
                midY: midY,
                height: height,
                maxX: maxX,
                tilt: tilt ?? 0
            )
        }
    }
}

private extension ReceiptFragmentTests {
    static var fragmentCases: [FragmentCase] {
        get throws {
            try CoreFixture.cases("receipt/receipt-fragments.json")
        }
    }
}
