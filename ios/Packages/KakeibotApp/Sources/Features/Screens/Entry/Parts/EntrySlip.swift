import Core
import DesignSystem
import SwiftUI

struct EntrySlip: View {
    @Environment(\.themeStyle.displayFont) private var themeFont
    @Environment(\.themeStyle.corner) private var corner

    let model: EntryModel
    let deck: EntryDeck
    let today: LocalDate
    let isMemoActive: Bool
    let isListening: Bool
    let preview: VoiceReading?
    let onSelect: (EntryDeck) -> Void
    let onMemo: () -> Void
    let onOpenItems: () -> Void
    let onReceipt: (() -> Void)?
    let onVoice: (() -> Void)?

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: corner.radius(20))

        VStack(spacing: 0) {
            fields

            amountRow

            memoBand
        }
        .background(Self.cardFill, in: shape)
        .clipShape(shape)
        .overlay {
            shape
                .strokeBorder(Palette.accent.opacity(.strong), lineWidth: 1)
        }
        .overlay {
            shape
                .inset(by: 1)
                .stroke(Self.shine, lineWidth: 1)
        }
        .shadow(color: Palette.shadow.opacity(.medium), radius: 8, y: 6)
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 20)
        .animation(.snappy, value: deck)
    }
}

private extension EntrySlip {
    var amountRow: some View {
        let isSelected = isSelected(.amount)
        let titleColor = isSelected ? Palette.accent : Palette.subtext

        return Button {
            onSelect(.amount)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "yensign")
                    .sansFont(.caption, weight: .heavy)
                    .foregroundStyle(Palette.backgroundBottom)
                    .frame(width: Self.markSize, height: Self.markSize)
                    .background(Self.gold, in: .circle)

                Text("金額")
                    .textFont(.caption, weight: .semibold)
                    .foregroundStyle(titleColor)
                    .fixedSize()

                if let status {
                    Text(status)
                        .textFont(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(Palette.hint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 8)

                amountFace
                    .layoutPriority(1)
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .frame(height: Self.amountHeight)
            .background {
                rowFace(isSelected: isSelected)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    var amountFace: some View {
        if isSelected(.amount) {
            amountText(color: .clear)
                .overlay {
                    Self.amountGold
                        .mask {
                            amountText(color: .black)
                        }
                }
        } else {
            amountText(color: idleAmountColor)
        }
    }

    @ViewBuilder
    var fields: some View {
        if model.type == .transfer {
            row(
                "振替",
                value: routeValue,
                target: .transfer
            ) {
                symbolMark("arrow.left.arrow.right")
            }

            row(
                "手数料",
                value: feeValue,
                target: .fee,
                isChanged: model.fee > 0
            ) {
                symbolMark("building.columns")
            }

            dateRow
        } else {
            row(
                "カテゴリ",
                value: shownCategory?.name ?? "選ぶ",
                target: .category
            ) {
                categoryMark
            }

            row(
                model.walletTitle,
                value: model.billText ?? model.walletName,
                target: .wallet(.source),
                isChanged: !model.isUsualWallet || model.billText != nil,
                isFromVoice: model.isWalletFromVoice
            ) {
                walletMark
            }

            dateRow
        }
    }

    var dateRow: some View {
        row(
            "日付",
            value: dateValue,
            target: .date,
            isChanged: model.date != today,
            isFromVoice: model.isDateFromVoice
        ) {
            dateMark
        }
    }

    @ViewBuilder
    var categoryMark: some View {
        if let category = shownCategory {
            iconMark(model.icon(for: category))
        } else {
            symbolMark("square.grid.2x2")
        }
    }

    @ViewBuilder
    var walletMark: some View {
        if let wallet = model.wallet(model.walletId) {
            iconMark(model.icon(for: wallet))
        } else {
            symbolMark("creditcard")
        }
    }

    var dateMark: some View {
        let shape = RoundedRectangle(cornerRadius: corner.radius(8))

        return VStack(spacing: 0) {
            Self.gold
                .frame(height: 5)

            Text("\(model.date.day)")
                .displayFont(.caption, weight: .bold)
                .monospacedDigit()
                .foregroundStyle(Palette.accentStrong)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: Self.markSize, height: Self.markSize)
        .background(Palette.backgroundBottom)
        .clipShape(shape)
        .overlay {
            shape
                .strokeBorder(Palette.accent.opacity(.medium), lineWidth: 1)
        }
    }

    var memoBand: some View {
        HStack(spacing: 8) {
            Button(action: onMemo) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "pencil")
                        .textFont(.caption, weight: .semibold)

                    Text(memoText)
                        .textFont(.footnote)
                        .underline(model.isMemoFromVoice, color: Palette.accent.opacity(.medium))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .foregroundStyle(memoColor)
                .frame(maxHeight: .infinity)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            if showsItems {
                EntryItemButton(
                    count: model.items.count,
                    total: model.itemTotal,
                    adjustment: model.itemAdjustment,
                    onOpen: onOpenItems
                )
                .fixedSize()
            }

            if let onReceipt {
                quickButton("doc.text.viewfinder", action: onReceipt)
            }

            if let onVoice {
                quickButton("mic", action: onVoice)
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .frame(height: Self.rowHeight)
    }

    func row(
        _ title: String,
        value: String,
        target: EntryDeck,
        isChanged: Bool = false,
        isFromVoice: Bool = false,
        @ViewBuilder mark: () -> some View
    ) -> some View {
        let isSelected = isSelected(target)
        let titleColor = isSelected ? Palette.accent : Palette.subtext
        let arrowColor = isSelected ? Palette.accent : Palette.hint
        let valueColor = isChanged ? Palette.amber : Palette.text

        return Button {
            onSelect(target)
        } label: {
            HStack(spacing: 8) {
                mark()

                Text(title)
                    .textFont(.caption, weight: .semibold)
                    .foregroundStyle(titleColor)
                    .fixedSize()

                Spacer(minLength: 8)

                Text(value)
                    .textFont(.subheadline, weight: .medium)
                    .foregroundStyle(valueColor)
                    .underline(isFromVoice, color: Palette.accent.opacity(.medium))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Image(systemName: "chevron.right")
                    .sansFont(.micro, weight: .bold)
                    .foregroundStyle(arrowColor)
            }
            .padding(.leading, 16)
            .padding(.trailing, 12)
            .frame(height: Self.rowHeight)
            .background {
                rowFace(isSelected: isSelected)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    func rowFace(isSelected: Bool) -> some View {
        ZStack(alignment: .leading) {
            if isSelected {
                Self.litFill

                Palette.accent
                    .frame(width: 3)
                    .clipShape(.rect(cornerRadius: 2))
                    .padding(.vertical, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            Palette.line
                .frame(height: 1)
        }
    }

    func iconMark(_ icon: Icon?) -> some View {
        let color = icon.flatMap { Color(hex: $0.color) } ?? Palette.accent

        return IconImage(icon, size: 12)
            .frame(width: Self.markSize, height: Self.markSize)
            .overlay {
                RoundedRectangle(cornerRadius: corner.radius(8))
                    .strokeBorder(color, lineWidth: 1.5)
            }
    }

    func symbolMark(_ systemImage: String) -> some View {
        Image(systemName: systemImage)
            .sansFont(.caption, weight: .bold)
            .foregroundStyle(Palette.accent)
            .frame(width: Self.markSize, height: Self.markSize)
            .overlay {
                RoundedRectangle(cornerRadius: corner.radius(8))
                    .strokeBorder(Palette.accent.opacity(.strong), lineWidth: 1.5)
            }
    }

    func quickButton(
        _ systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .textFont(.caption2, weight: .semibold)
                .foregroundStyle(Palette.accent)
                .frame(width: 28, height: 28)
                .overlay {
                    Circle()
                        .stroke(Palette.accent.opacity(.medium), lineWidth: 1)
                }
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
    }

    func amountText(color: Color) -> some View {
        AmountText(
            shownAmount,
            font: .fixed(amountFont),
            color: color
        )
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }
}

private extension EntrySlip {
    static let listeningNote = "聞いています"
    static let amountHeight: CGFloat = 60
    static let rowHeight: CGFloat = 44
    static let markSize: CGFloat = 24

    static var amountGold: LinearGradient {
        LinearGradient(
            colors: [Palette.accentStrong, Palette.accent],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var gold: LinearGradient {
        LinearGradient(
            colors: [Palette.accentStrong, Palette.accent, Palette.accentDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var cardFill: LinearGradient {
        LinearGradient(
            colors: [
                Palette.accent.mix(with: Palette.cardTop, by: 0.84),
                Palette.cardTop,
                Palette.cardBottom
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var litFill: LinearGradient {
        LinearGradient(
            colors: [Palette.accent.opacity(.soft), .clear],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var shine: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .white.opacity(0.3), location: 0),
                .init(color: .clear, location: 0.3)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var idleAmountColor: Color {
        shownAmount > 0 ? Palette.text : Palette.hint
    }

    var routeValue: String {
        guard
            let source = model.wallet(model.walletId)?.name,
            let destination = model.wallet(model.toWalletId)?.name
        else {
            return "口座を選ぶ"
        }

        return "\(source) → \(destination)"
    }

    var feeValue: String {
        model.fee > 0 ? AmountText.text(model.fee) : "なし"
    }

    var dateValue: String {
        let day = EntryModel.shortDateText(for: model.date, today: today)
        return "\(day)（\(model.date.weekday.shortName)）"
    }

    var memoText: String {
        model.memo.isEmpty ? "\(model.memoPrompt)をメモ" : model.memo
    }

    var memoColor: Color {
        if isMemoActive {
            return Palette.accent
        }

        return model.memo.isEmpty ? Palette.hint : Palette.subtext
    }

    var showsItems: Bool {
        model.showsItems && !model.items.isEmpty
    }

    var shownCategory: EntryCategory? {
        guard
            isListening,
            let id = preview?.categoryId,
            let category = model.categories.first(where: { $0.id == id })
        else {
            return model.selectedCategory
        }

        return category
    }

    var shownAmount: Int {
        if isListening, let amount = preview?.amount {
            return amount
        }

        return model.amount
    }

    var amountFont: Font {
        .display(size: 36, weight: .semibold, in: themeFont)
    }

    var status: String? {
        isListening ? Self.listeningNote : model.expressionText
    }

    func isSelected(_ target: EntryDeck) -> Bool {
        deck.field(for: model.type) == target
    }
}
