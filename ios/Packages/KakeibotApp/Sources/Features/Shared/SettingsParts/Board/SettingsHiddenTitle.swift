import DesignSystem
import FeatureModels
import SwiftUI

struct SettingsHiddenTitle: View {
    let fold: SettingsFold
    let title: String
    let count: Int

    var onDeleteAll: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Button {
                    withAnimation(.snappy) {
                        fold.setClosed(!fold.isClosed)
                    }
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: "chevron.right")
                            .sansFont(.caption, weight: .semibold)
                            .foregroundStyle(Palette.accent)
                            .rotationEffect(chevronAngle)

                        SectionTitle("\(title)（\(count)）")
                    }
                    .frame(minHeight: 32)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)

                Spacer()

                if !fold.isClosed,
                   let onDeleteAll {
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

            if !fold.isClosed {
                Text("長押しで上に動かすと戻せます")
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)
            }
        }
        .animation(.snappy, value: fold.isClosed)
        .task {
            await fold.load()
        }
    }
}

private extension SettingsHiddenTitle {
    var chevronAngle: Angle {
        .degrees(fold.isClosed ? 0 : 90)
    }
}
