import Foundation

public struct ReceiptFragment: Hashable, Sendable {
    public var text: String
    public var minX: Double
    public var midY: Double
    public var height: Double
    public var maxX: Double
    public var tilt: Double

    public init(
        text: String,
        minX: Double,
        midY: Double,
        height: Double,
        maxX: Double? = nil,
        tilt: Double = 0
    ) {
        self.text = text
        self.minX = minX
        self.midY = midY
        self.height = height
        self.maxX = maxX ?? minX
        self.tilt = tilt
    }
}

public extension ReceiptFragment {
    static func lines(of fragments: [ReceiptFragment]) -> [String] {
        let skew = skew(of: fragments)

        let sorted = fragments
            .filter {
                !$0.trimmedText.isEmpty
            }
            .map {
                $0.leveled(by: skew)
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
    static let minSkewWidth = 0.2
    static let maxSkew = 0.3

    var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var midX: Double {
        (minX + maxX) / 2
    }

    static func skew(of fragments: [ReceiptFragment]) -> Double {
        let tilts = fragments
            .filter {
                $0.maxX - $0.minX >= minSkewWidth && abs($0.tilt) <= maxSkew
            }
            .map(\.tilt)
            .sorted()

        guard !tilts.isEmpty else {
            return 0
        }

        return tilts[tilts.count / 2]
    }

    func leveled(by skew: Double) -> ReceiptFragment {
        var fragment = self
        fragment.midY = midY - skew * (midX - 0.5)
        return fragment
    }

    func isOnSameRow(as anchor: ReceiptFragment) -> Bool {
        let height = min(height, anchor.height)
        return abs(midY - anchor.midY) <= height * Self.rowTolerance
    }
}
