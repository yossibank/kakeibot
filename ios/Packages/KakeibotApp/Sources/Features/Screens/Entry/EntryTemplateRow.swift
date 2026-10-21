import Core
import DesignSystem
import SwiftUI

struct EntryTemplateRow: View {
    let model: EntryModel
    let onUse: (EntryTemplate) -> Void
    let onAdd: () -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                ForEach(model.templates) { template in
                    button(template)
                }

                Button {
                    onAdd()
                } label: {
                    Label("今の入力を保存", systemImage: "plus")
                        .textFont(size: .caption)
                        .foregroundStyle(Palette.accent)
                        .padding(.horizontal, 12)
                        .frame(height: Self.height)
                        .overlay {
                            Capsule()
                                .stroke(
                                    Palette.accent.opacity(.medium),
                                    style: .dashed
                                )
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 1)
        }
        .scrollIndicators(.hidden)
        .frame(height: Self.height + 2)
    }
}

private extension EntryTemplateRow {
    func button(_ template: EntryTemplate) -> some View {
        let isApplied = model.isApplied(template)
        let icon = model.icon(for: template)
        let amount = template.amount.map { AmountText.text($0) } ?? "入力"
        let amountColor = template.amount == nil
            ? Palette.subtext
            : Palette.accentStrong

        return Button {
            onUse(template)
        } label: {
            HStack(spacing: 6) {
                IconImage(icon, size: 12)
                    .foregroundStyle(Palette.accent)

                Text(template.name)
                    .foregroundStyle(Palette.text)

                Text(amount)
                    .displayFont(.caption)
                    .foregroundStyle(amountColor)
            }
            .textFont(size: .caption)
            .padding(.leading, 6)
            .padding(.trailing, 12)
            .frame(height: Self.height)
            .background(EntrySheet.categoryFill(isApplied), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(Self.stroke(isApplied), lineWidth: 1)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private extension EntryTemplateRow {
    static let height: CGFloat = 34

    static func stroke(_ isApplied: Bool) -> Color {
        isApplied ? Palette.accent : Palette.accent.opacity(.soft)
    }
}
