import DesignSystem
import SwiftUI

struct SettingsHiddenTitle: View {
    let flag: SettingsScreenFlag
    let title: String
    let count: Int

    var body: some View {
        Button {
            Task {
                await flag.set(!flag.isOn)
            }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Palette.gold)
                    .rotationEffect(.degrees(flag.isOn ? 90 : 0))

                SettingsSectionTitle("\(title)（\(count)）")

                Spacer()

                if flag.isOn {
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
        .animation(.snappy, value: flag.isOn)
        .task {
            await flag.load()
        }
    }
}
