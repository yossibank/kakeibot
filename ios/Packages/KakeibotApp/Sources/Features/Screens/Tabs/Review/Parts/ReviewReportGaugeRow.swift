import Core
import DesignSystem
import SwiftUI

struct ReviewReportGaugeRow<Detail: View>: View {
    let pace: ReviewPace?
    let limitName: String
    let showsMarker: Bool

    @ViewBuilder let detail: Detail

    var body: some View {
        ViewThatFits(in: .horizontal) {
            row(size: ReviewReportGauge.regularSize)
            row(size: ReviewReportGauge.compactSize)
        }
    }
}

private extension ReviewReportGaugeRow {
    func row(size: CGFloat) -> some View {
        HStack(spacing: 16) {
            if let pace {
                ReviewReportGauge(
                    pace: pace,
                    limitName: limitName,
                    showsMarker: showsMarker,
                    size: size
                )
            }

            detail
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
