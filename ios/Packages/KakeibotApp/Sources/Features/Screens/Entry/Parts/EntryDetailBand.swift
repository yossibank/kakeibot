import Core
import DesignSystem
import SwiftUI

struct EntryDetailBand: View {
    @Environment(\.themeStyle.corner) private var corner

    let model: EntryModel
    let today: LocalDate
    let onWallet: () -> Void
    let onFee: () -> Void
    let onDate: () -> Void
    let onMemo: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let unit = proxy.size.width / totalWeight

            HStack(spacing: 0) {
                if showsWallet {
                    walletCell
                        .frame(width: unit * Self.walletWeight)
                } else {
                    feeCell
                        .frame(width: unit * Self.walletWeight)
                }

                divider

                dateCell
                    .frame(width: unit * Self.dateWeight)

                divider

                memoCell
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: Self.height)
        .background(Palette.panel.opacity(.strong))
        .clipShape(.rect(cornerRadius: corner.radius(16)))
        .overlay {
            RoundedRectangle(cornerRadius: corner.radius(16))
                .stroke(Palette.line, lineWidth: 1)
        }
        .buttonStyle(.plain)
    }
}

private extension EntryDetailBand {
    var divider: some View {
        Rectangle()
            .fill(Palette.line)
            .frame(width: 1)
    }

    var walletCell: some View {
        Button(action: onWallet) {
            cell(
                title: walletTitle,
                value: model.walletName,
                isChanged: !model.isUsualWallet || model.billText != nil,
                showsChevron: true
            )
        }
    }

    var feeCell: some View {
        Button(action: onFee) {
            cell(
                title: "手数料",
                value: model.fee > 0 ? AmountText.text(model.fee) : "なし",
                valueColor: model.fee > 0 ? Palette.text : Palette.subtext,
                isChanged: model.fee > 0,
                showsChevron: true
            )
        }
    }

    var dateCell: some View {
        Button(action: onDate) {
            cell(
                title: EntryModel.dateTitle(for: model.date, today: today),
                value: EntryModel.dateText(for: model.date, today: today),
                shortValue: EntryModel.shortDateText(for: model.date, today: today),
                isChanged: model.date != today,
                showsChevron: true
            )
        }
    }

    var memoCell: some View {
        Button(action: onMemo) {
            cell(
                title: "メモ",
                value: memoText,
                valueColor: model.memo.isEmpty ? Palette.subtext : Palette.text,
                isChanged: false,
                showsChevron: false
            )
        }
    }

    func cell(
        title: String,
        value: String,
        shortValue: String? = nil,
        valueColor: Color = Palette.text,
        isChanged: Bool,
        showsChevron: Bool
    ) -> some View {
        let tint = isChanged ? Palette.amber : nil
        let fill = isChanged ? Palette.amber.opacity(.subtle) : Color.clear
        let valueTint = tint ?? valueColor

        return VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .textFont(.caption2)
                .foregroundStyle(tint ?? Palette.subtext)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            HStack(spacing: 4) {
                if let shortValue {
                    ViewThatFits(in: .horizontal) {
                        valueText(value, color: valueTint)
                        valueText(value, color: valueTint, style: .caption)
                        valueText(shortValue, color: valueTint)
                    }
                    .layoutPriority(1)
                } else {
                    valueText(value, color: valueTint)
                }

                if showsChevron {
                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .sansFont(.micro, weight: .semibold)
                        .foregroundStyle(tint ?? Palette.subtext)
                }
            }
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(fill)
        .contentShape(.rect)
    }

    func valueText(
        _ text: String,
        color: Color,
        style: Font.TextStyle = .subheadline
    ) -> some View {
        Text(text)
            .textFont(style)
            .monospacedDigit()
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

private extension EntryDetailBand {
    static let height: CGFloat = 64
    static let walletWeight: CGFloat = 1
    static let dateWeight: CGFloat = 1.25
    static let memoWeight: CGFloat = 1

    var showsWallet: Bool {
        model.type != .transfer
    }

    var totalWeight: CGFloat {
        Self.walletWeight + Self.dateWeight + Self.memoWeight
    }

    var walletTitle: String {
        model.billText ?? model.walletTitle
    }

    var memoText: String {
        let firstLine = model.memo.split(whereSeparator: \.isNewline).first
        return firstLine.map(String.init) ?? "＋ \(model.memoHint)"
    }
}
