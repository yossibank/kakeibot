import Foundation

public struct ReceiptFragment: Hashable, Sendable {
    public var text: String
    public var minX: Double
    public var midY: Double
    public var height: Double

    public init(
        text: String,
        minX: Double,
        midY: Double,
        height: Double
    ) {
        self.text = text
        self.minX = minX
        self.midY = midY
        self.height = height
    }
}

public extension ReceiptFragment {
    static func lines(of fragments: [ReceiptFragment]) -> [String] {
        let sorted = fragments
            .filter {
                !$0.trimmedText.isEmpty
            }
            .sorted {
                $0.midY < $1.midY
            }

        var rows: [[ReceiptFragment]] = []

        for fragment in sorted {
            if let last = rows.last,
               let anchor = last.first,
               fragment.isOnSameRow(as: anchor) {
                rows[rows.count - 1].append(fragment)
            } else {
                rows.append([fragment])
            }
        }

        return rows.map { row in
            row
                .sorted {
                    $0.minX < $1.minX
                }
                .map(\.trimmedText)
                .joined(separator: " ")
        }
    }
}

private extension ReceiptFragment {
    static let rowTolerance = 0.5

    var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func isOnSameRow(as anchor: ReceiptFragment) -> Bool {
        let height = min(height, anchor.height)
        return abs(midY - anchor.midY) <= height * Self.rowTolerance
    }
}
