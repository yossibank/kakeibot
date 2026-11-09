import DesignSystem
import SwiftUI

struct BillProgressNote: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            BillRing(progress: 0.6)
                .padding(.top, 1)

            Text(BillText.progressNote)
                .textFont(.caption2)
                .foregroundStyle(Palette.hint)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
