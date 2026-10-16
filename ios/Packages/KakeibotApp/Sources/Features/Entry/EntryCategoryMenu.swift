import Core
import DesignSystem
import SwiftUI

struct EntryCategoryMenu: View {
    let icon: Icon?
    let name: String
    let onEdit: () -> Void
    let onHide: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                IconImage(icon, size: 15)
                    .foregroundStyle(Palette.gold)

                Text(name)
                    .font(.system(size: 14, design: .serif))
                    .tracking(1)
                    .foregroundStyle(Palette.champagne)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(height: 44)

            hairline

            row(
                "このカテゴリを編集",
                systemImage: "square.and.pencil",
                action: onEdit
            )

            hairline

            row(
                "非表示にする",
                note: "設定のカテゴリから戻せます",
                systemImage: "eye.slash",
                action: onHide
            )
        }
        .frame(width: Self.width)
        .background(Palette.drawer, in: .rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Palette.gold.opacity(0.45), lineWidth: 0.8)
        }
        .shadow(color: .black.opacity(0.5), radius: 24, y: 12)
    }
}

extension EntryCategoryMenu {
    static let width: CGFloat = 236
}

private extension EntryCategoryMenu {
    var hairline: some View {
        Rectangle()
            .fill(Palette.gold.opacity(0.16))
            .frame(height: 0.5)
            .padding(.horizontal, 12)
    }

    func row(
        _ title: String,
        note: String? = nil,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Palette.gold)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(Palette.ink)

                    if let note {
                        Text(note)
                            .font(.caption2)
                            .foregroundStyle(Palette.mist)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 48)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
