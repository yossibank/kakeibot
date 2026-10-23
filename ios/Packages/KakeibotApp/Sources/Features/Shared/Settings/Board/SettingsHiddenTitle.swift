import DesignSystem
import SwiftUI

struct SettingsHiddenTitle: View {
    let flag: SettingsScreenFlag
    let title: String
    let count: Int

    var onDeleteAll: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Button {
                    withAnimation(.snappy) {
                        flag.set(!flag.isOn)
                    }
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Palette.accent)
                            .rotationEffect(.degrees(flag.isOn ? 90 : 0))

                        SettingsSectionTitle("\(title)（\(count)）")
                    }
                    .frame(minHeight: 32)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)

                Spacer()

                if flag.isOn, let onDeleteAll {
                    Button(action: onDeleteAll) {
                        Label("まとめて削除", systemImage: "trash")
                            .textFont(.caption)
                            .foregroundStyle(Palette.rose)
                            .frame(minHeight: 32)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }

            if flag.isOn {
                Text("長押しで上に動かすと戻せます")
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)
            }
        }
        .animation(.snappy, value: flag.isOn)
        .task {
            await flag.load()
        }
    }
}
