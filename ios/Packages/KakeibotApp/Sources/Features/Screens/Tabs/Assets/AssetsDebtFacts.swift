import DesignSystem
import SwiftUI

struct AssetsDebtFacts: View {
    let facts: [Fact]
    let isInline: Bool

    var body: some View {
        if isInline {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                ForEach(Array(facts.enumerated()), id: \.offset) { index, fact in
                    if index > 0 {
                        Text("・")
                            .textFont(.caption)
                            .foregroundStyle(Palette.subtext)
                    }

                    line(fact)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(facts, id: \.self) { fact in
                    line(fact)
                }
            }
        }
    }
}

extension AssetsDebtFacts {
    struct Fact: Hashable {
        let lead: String?
        let value: String
        let trail: String?

        var text: String {
            [lead, value, trail].compactMap(\.self).joined(separator: " ")
        }

        init(
            lead: String? = nil,
            _ value: String,
            trail: String? = nil
        ) {
            self.lead = lead
            self.value = value
            self.trail = trail
        }
    }
}

private extension AssetsDebtFacts {
    func line(_ fact: Fact) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            if let lead = fact.lead {
                Text(lead)
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Text(fact.value)
                .textFont(.headline)
                .monospacedDigit()
                .foregroundStyle(Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if let trail = fact.trail {
                Text(trail)
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }
}
