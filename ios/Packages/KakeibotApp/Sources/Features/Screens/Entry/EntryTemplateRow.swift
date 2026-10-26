import Core
import DesignSystem
import SwiftUI

struct EntryTemplateRow: View {
    let model: EntryModel
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

                if !secondRow.isEmpty {
                    HStack(spacing: Self.spacing) {
                        ForEach(secondRow) { template in
                            button(template)
                        }

                        addButton
                    }
                }
            }
            .padding(.vertical, 1)
        }
        .scrollIndicators(.hidden)
    }
}

private extension EntryTemplateRow {
    var addButton: some View {
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
            HStack(spacing: 8) {
                IconImage(icon, size: 12)
                    .foregroundStyle(Palette.accent)

                Text(template.name)
                    .foregroundStyle(Palette.text)

                Text(amount)
                    .displayFont(.caption)
                    .foregroundStyle(amountColor)
            }
            .textFont(size: .caption)
            .padding(.leading, 8)
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
    static let spacing: CGFloat = 8
    static let minimumForTwoRows = 3

    var splitIndex: Int {
        let count = model.templates.count
        return count < Self.minimumForTwoRows ? count : (count + 1) / 2
    }

    var firstRow: ArraySlice<EntryTemplate> {
        model.templates.prefix(splitIndex)
    }

    var secondRow: ArraySlice<EntryTemplate> {
        model.templates.dropFirst(splitIndex)
    }

    static func stroke(_ isApplied: Bool) -> Color {
        isApplied ? Palette.accent : Palette.accent.opacity(.soft)
    }
}
