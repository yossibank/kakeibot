import Core
import DesignSystem
import Store
import SwiftUI

extension EntryItemSheet {
    var receipt: some View {
        VStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(dateText)
                    .textFont(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)

                TextField(
                    "店名",
                    text: $model.store,
                    prompt: Text("店名を入れる").foregroundStyle(Palette.hint)
                )
                .textFont(.subheadline, weight: .semibold)
                .foregroundStyle(Palette.text)
                .multilineTextAlignment(.center)
                .tint(Palette.accent)
                .submitLabel(.done)
                .focused($focus, equals: .store)
            }

            EntryReceiptRule(style: .dashed)

            if model.items.isEmpty {
                VStack(spacing: 4) {
                    Text("品目はまだありません")
                        .textFont(.subheadline)
                        .foregroundStyle(Palette.subtext)

                    Text("下の「品目を追加」から追加できます。")
                        .textFont(.caption)
                        .foregroundStyle(Palette.hint)
                }
                .frame(maxWidth: .infinity, minHeight: 72)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(model.items.enumerated()), id: \.offset) { index, item in
                        itemRow(item, at: index)
                            .id(index)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }

            EntryReceiptRule(style: .dashed)

            summaryLine("小計", amount: model.itemTotals.subtotal)

            if !model.itemTotals.taxes.isEmpty {
                taxModeLine
            }

            if !model.itemTotals.taxes.isEmpty {
                EntryReceiptTaxBreakdown(
                    taxes: model.itemTotals.taxes,
                    taxIncluded: model.taxIncluded
                )
            }

            if model.hasItemAdjustment {
                adjustmentLine

                if !model.suspectItemIndices.isEmpty {
                    suspectHint
                }
            }

            EntryReceiptRule(style: .double)

            HStack(alignment: .firstTextBaseline) {
                Text("合計")
                    .textFont(.subheadline, weight: .semibold)
                    .foregroundStyle(Palette.text)

                Spacer()

                AmountText(
                    model.amount,
                    font: .size(.title, weight: .bold),
                    color: Palette.accentStrong
                )
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            }

            if !model.items.isEmpty {
                HStack {
                    Text("お買上点数")
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)

                    Spacer()

                    Text("\(model.itemCount)点")
                        .textFont(.caption)
                        .monospacedDigit()
                        .foregroundStyle(Palette.subtext)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 28)
        .background {
            receiptShape
                .fill(Palette.paper)
                .shadow(color: Palette.shadow.opacity(0.6), radius: 12, y: 4)
        }
        .overlay {
            receiptShape
                .stroke(Palette.paperEdge, lineWidth: 1)
        }
    }

    var adjustmentLine: some View {
        HStack(spacing: 8) {
            Text("差額")
                .textFont(.subheadline)
                .foregroundStyle(Palette.amber)

            Button {
                model.adjustToItems()
            } label: {
                Text("調整")
                    .textFont(.caption, weight: .semibold)
                    .foregroundStyle(Palette.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .overlay {
                        Capsule()
                            .stroke(Palette.accent.opacity(.medium), lineWidth: 1)
                    }
                    .frame(minHeight: 32)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .disabled(!model.canAdjustToItems)

            Spacer()

            AmountText(
                model.itemAdjustment,
                font: .style(.subheadline),
                color: Palette.amber
            )
        }
    }

    var taxModeLine: some View {
        HStack(spacing: 4) {
            Text("税の計算")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)

            Spacer()

            CapsulePicker(
                selection: Binding(
                    get: { model.taxIncluded },
                    set: { model.setTaxIncluded($0) }
                ),
                options: Self.taxModeOptions,
                size: .small
            )
            .frame(width: Self.taxModeWidth)
        }
    }

    var suspectHint: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.magnifyingglass")

            Text("色の付いた行が、読み違えているかもしれません")
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .textFont(.caption)
        .foregroundStyle(Palette.amber)
    }

    func itemRow(
        _ item: EntryItem.Draft,
        at index: Int
    ) -> some View {
        let isEditing = isSlipOpen && editingIndex == index
        let isSuspect = model.suspectItemIndices.contains(index)
        let isNegative = item.amount < 0
        let amountColor = isSuspect ? Palette.amber : isNegative ? Palette.rose : Palette.text

        return SwipeRow(
            id: index,
            openId: $openIndex,
            actionInset: 2
        ) {
            edit(index)
        } onAction: {
            remove(index)
        } content: {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(item.trimmedName)
                            .textFont(.subheadline)
                            .foregroundStyle(isNegative ? Palette.rose : Palette.text)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        if showsRates, let rate = item.taxRate {
                            EntryReceiptTaxRateBadge(rate: rate)
                        }
                    }

                    if let quantity = EntryModel.quantityText(for: item) {
                        Text(quantity)
                            .textFont(.caption)
                            .monospacedDigit()
                            .foregroundStyle(Palette.subtext)
                    }
                }
                .padding(.leading, isNegative ? Self.discountIndent : 0)
                .layoutPriority(1)

                EntryReceiptLeader()

                AmountText(
                    item.amount,
                    font: .style(.subheadline),
                    color: amountColor
                )
                .layoutPriority(1)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background {
                ZStack {
                    Rectangle()
                        .fill(Palette.paper)

                    if isEditing {
                        Rectangle()
                            .fill(Palette.accent.opacity(.subtle))
                    } else if isSuspect {
                        Rectangle()
                            .fill(Palette.amber.opacity(.subtle))
                            .overlay(alignment: .leading) {
                                Rectangle()
                                    .fill(Palette.amber)
                                    .frame(width: 2)
                            }
                    }
                }
            }
        }
        .padding(.horizontal, -4)
    }

    func summaryLine(
        _ title: String,
        amount: Int
    ) -> some View {
        HStack {
            Text(title)
                .textFont(.subheadline)
                .foregroundStyle(Palette.subtext)

            Spacer()

            AmountText(amount, font: .style(.subheadline), color: Palette.text)
        }
    }
}
