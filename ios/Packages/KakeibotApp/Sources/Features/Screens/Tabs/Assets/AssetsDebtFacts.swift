import DesignSystem
import SwiftUI

struct AssetsDebtFacts: View {
    let facts: [Fact]

    var body: some View {
        RowOrColumnLayout(rowSpacing: 8, columnSpacing: 4) {
            ForEach(facts, id: \.self) { fact in
                chip(fact)
            }
        }
    }
}

extension AssetsDebtFacts {
    struct Fact: Hashable {
        let lead: String?
        let value: String
        let trail: String?

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
    func chip(_ fact: Fact) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            if let lead = fact.lead {
                Text(lead)
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)
            }

            Text(fact.value)
                .textFont(.subheadline, weight: .semibold)
                .monospacedDigit()
                .foregroundStyle(Palette.text)

            if let trail = fact.trail {
                Text(trail)
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Palette.accent.opacity(.faint), in: Capsule())
    }
}
