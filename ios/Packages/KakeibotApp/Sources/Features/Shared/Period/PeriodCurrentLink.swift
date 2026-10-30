import DesignSystem
import SwiftUI

struct PeriodCurrentLink: View {
    let title: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text("·")
                .foregroundStyle(Palette.subtext)

            Button(action: action) {
                HStack(spacing: 2) {
                    Text("\(title)へ")

                    Image(systemName: "arrow.uturn.backward")
                        .imageScale(.small)
                }
                .foregroundStyle(Palette.accent)
                .tapArea(Self.tapOutsets)
            }
            .buttonStyle(.plain)
        }
        .textFont(size: .caption)
        .lineLimit(1)
        .fixedSize()
        .transition(.opacity)
    }
}

private extension PeriodCurrentLink {
    static let tapOutsets = EdgeInsets(
        top: 10,
        leading: 4,
        bottom: 10,
        trailing: 4
    )
}
