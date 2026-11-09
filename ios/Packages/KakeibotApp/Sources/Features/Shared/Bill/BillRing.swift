import DesignSystem
import SwiftUI

struct BillRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Palette.accent.opacity(.soft), lineWidth: 2)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Palette.accent,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .padding(1)
        .frame(width: 14, height: 14)
    }
}
