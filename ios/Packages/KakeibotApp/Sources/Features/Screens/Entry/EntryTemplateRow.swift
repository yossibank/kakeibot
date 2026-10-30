import Core
import DesignSystem
import SwiftUI

struct EntryTemplateRow: View {
    let model: EntryModel
    let isCompact: Bool
    let onUse: (EntryTemplate) -> Void
    let onAdd: () -> Void

    var body: some View {
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: Self.spacing) {
                HStack(spacing: Self.spacing) {
                    ForEach(firstRow) { template in
                        button(template)
                    }

                    if secondRow.isEmpty {
                        addButton
                    }
                }
                .fixedSize()

                if !secondRow.isEmpty {
                    HStack(spacing: Self.spacing) {
                        ForEach(secondRow) { template in
                            button(template)
                        }

                        addButton
                    }
                    .fixedSize()
                }
            }
            .padding(.vertical, 1)
        }
        .scrollIndicators(.hidden)
    }
}

private extension EntryTemplateRow {
    var addButton: some View {
        ChipButton(
            "今の入力を保存",
            systemImage: "plus",
            outline: .dashed,
            action: onAdd
        )
    }

    func button(_ template: EntryTemplate) -> some View {
        let icon = model.icon(for: template)
        let amount = template.amount.map { AmountText.text($0) } ?? "毎回入れる"

        let amountColor = template.amount == nil
            ? Palette.subtext
            : Palette.accentStrong

        return ChipButton(isSelected: model.isApplied(template)) {
            onUse(template)
        } content: {
            HStack(spacing: 8) {
                IconImage(icon, size: 12)
                    .foregroundStyle(Palette.accent)

                Text(template.name)

                Text(amount)
                    .displayFont(.caption)
                    .foregroundStyle(amountColor)
            }
        }
    }
}

private extension EntryTemplateRow {
    static let spacing: CGFloat = 8
    static let minimumForTwoRows = 3

    var splitIndex: Int {
        let count = model.templates.count
        let isOneRow = isCompact || count < Self.minimumForTwoRows
        return isOneRow ? count : (count + 1) / 2
    }

    var firstRow: ArraySlice<EntryTemplate> {
        model.templates.prefix(splitIndex)
    }

    var secondRow: ArraySlice<EntryTemplate> {
        model.templates.dropFirst(splitIndex)
    }
}
