import Core
import DesignSystem
import SwiftUI

struct ReviewReportLead: View {
    let caption: String
    let value: String
    let suffix: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(caption)
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    amount
                        .fixedSize()

                    suffixText
                        .padding(.leading, 2)
                }

                VStack(alignment: .leading, spacing: 0) {
                    amount

                    suffixText
                }
            }
            .foregroundStyle(color)
        }
    }
}

private extension ReviewReportLead {
    var amount: some View {
        HStack(alignment: .lastTextBaseline, spacing: 2) {
            Text(value)
                .displayFont(.title, weight: .bold)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text("円")
                .displayFont(.small, weight: .bold)
                .fixedSize()
        }
    }

    var suffixText: some View {
        Text(suffix)
            .textFont(.footnote, weight: .bold)
            .fixedSize()
    }
}
