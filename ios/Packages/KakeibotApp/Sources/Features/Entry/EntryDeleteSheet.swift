import Core
import DesignSystem
import SwiftUI

struct EntryDeleteSheet: View {
    @Environment(\.dismiss) private var dismiss

    let model: EntryModel
    let today: LocalDate
    let onDelete: () -> Void

    var body: some View {
        FittedSheet {
            VStack(spacing: 14) {
                Image(systemName: "trash")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(Palette.rose)
                    .frame(width: 52, height: 52)
                    .overlay {
                        Circle()
                            .stroke(Palette.rose.opacity(0.6), lineWidth: 1)
                    }
                    .accessibilityHidden(true)

                VStack(spacing: 6) {
                    Text("この記録を消しますか")
                        .font(.headline)
                        .foregroundStyle(Palette.champagne)

                    Text("消すと元に戻せません")
                        .font(.caption)
                        .foregroundStyle(Palette.mist)
                }

                summary

                Button {
                    dismiss()
                    onDelete()
                } label: {
                    Text("消す")
                        .font(.body.weight(.bold))
                        .foregroundStyle(Palette.rose)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Palette.rose.opacity(0.12), in: Capsule())
                        .overlay(Capsule().stroke(Palette.rose, lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button("やめる") {
                    dismiss()
                }
                .foregroundStyle(Palette.mist)
                .frame(minHeight: 44)
            }
        }
    }
}

private extension EntryDeleteSheet {
    var summary: some View {
        let icon = model.selectedCategory.flatMap(model.icon(for:))

        return HStack(spacing: 12) {
            IconImage(icon, size: 20)
                .foregroundStyle(Palette.gold)

            VStack(alignment: .leading, spacing: 2) {
                Text(model.selectedCategory?.name ?? "")
                    .font(.subheadline)
                    .foregroundStyle(Palette.ink)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Palette.mist)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(AmountText.text(model.amount))
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(Palette.champagne)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Palette.line, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

private extension EntryDeleteSheet {
    var detail: String {
        let date = EntryModel.dateText(for: model.date, today: today)
        let parts = [date, model.walletName, model.memo].filter { !$0.isEmpty }
        return parts.joined(separator: "・")
    }
}
