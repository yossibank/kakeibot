import DesignSystem
import SwiftUI

struct HomeCardHeader: View {
    let title: String
    let onClose: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .textFont(.footnote)
                .foregroundStyle(Palette.accentStrong)
                .contentTransition(.numericText())

            Spacer()

            RingButton(
                systemImage: "xmark",
                size: .small,
                action: onClose
            )
        }
        .padding(.top, 8)
    }
}
