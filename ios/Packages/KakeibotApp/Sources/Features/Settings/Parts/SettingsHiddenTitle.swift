import DesignSystem
import SwiftUI

struct SettingsHiddenTitle: View {
    @Binding var isOpen: Bool

    let title: String
    let count: Int

    var body: some View {
        Button {
            withAnimation(.snappy) {
                isOpen.toggle()
            }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Palette.gold)
                    .rotationEffect(.degrees(isOpen ? 90 : 0))

                SettingsSectionTitle("\(title)（\(count)）")

                Spacer()

                if isOpen {
                    Text("長押しで上に動かすと戻せます")
                        .font(.caption2)
                        .foregroundStyle(Palette.mist)
                        .lineLimit(1)
                }
            }
            .frame(minHeight: 32)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
