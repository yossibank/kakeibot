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

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Palette.subtext)
                    .frame(width: 24, height: 24)
                    .background(Palette.line, in: Circle())
                    .frame(width: 32, height: 32)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }
}
