import DesignSystem
import Store
import SwiftUI

struct SettingsMenuSyncRow: View {
    let status: SyncStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title = status.troubleTitle {
                SettingsRow(
                    "同期と共有",
                    systemImage: "icloud",
                    tint: nil,
                    trailingImage: "chevron.right",
                    accessory: troubleValue(title)
                )
            } else {
                SettingsRow(
                    "同期と共有",
                    systemImage: "icloud",
                    tint: nil,
                    trailingImage: "chevron.right",
                    accessory: SettingsRowValue(
                        value: status.isEnabled ? "オン" : "オフ",
                        shortValue: nil
                    )
                )
            }

            if let message = status.troubleMessage {
                HStack(spacing: 12) {
                    Color.clear
                        .frame(width: 22, height: 0)

                    Text(message)
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, 12)
            }
        }
    }
}

private extension SettingsMenuSyncRow {
    var troubleDot: some View {
        Circle()
            .fill(Palette.amber)
            .frame(width: 9, height: 9)
    }

    func troubleValue(_ title: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 4) {
                troubleDot

                Text(title)
                    .textFont(.footnote)
                    .lineLimit(1)
                    .fixedSize()
            }

            troubleDot
        }
        .foregroundStyle(Palette.amber)
    }
}
