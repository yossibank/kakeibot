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
                isChanged: model.date != today,
                showsChevron: true,
                trailingInset: Self.pillWidth
            )
        }
        .overlay(alignment: .topTrailing) {
            Button {
                withAnimation(.snappy) {
                    model.date = isToday ? today.adding(days: -1) : today
                }
            } label: {
                Text(isToday ? "昨日" : "今日")
                    .textFont(.caption2)
                    .foregroundStyle(Palette.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 1)
                    .overlay {
                        Capsule()
                            .stroke(Palette.accent.opacity(.medium), lineWidth: 1)
                    }
                    .padding(.top, 8)
                    .padding(.trailing, 8)
                    .frame(minWidth: 44, minHeight: 44, alignment: .topTrailing)
                    .contentShape(.rect)
            }
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
        valueColor: Color = Palette.text,
        isChanged: Bool,
        showsChevron: Bool,
        trailingInset: CGFloat = 0
    ) -> some View {
        let tint = isChanged ? Palette.amber : nil

        return VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .textFont(.caption2)
                .foregroundStyle(tint ?? Palette.subtext)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.trailing, trailingInset)

            HStack(spacing: 4) {
                Text(value)
                    .textFont(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(tint ?? valueColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

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
        .background(isChanged ? Palette.amber.opacity(.subtle) : Color.clear)
        .contentShape(.rect)
    }
}

private extension EntryDetailBand {
    static let height: CGFloat = 64
    static let walletWeight: CGFloat = 1
    static let dateWeight: CGFloat = 1.25
    static let memoWeight: CGFloat = 1
    static let pillWidth: CGFloat = 40

    var showsWallet: Bool {
        model.type != .transfer
    }

    var totalWeight: CGFloat {
        Self.walletWeight + Self.dateWeight + Self.memoWeight
    }

    var walletTitle: String {
        model.billText ?? model.walletTitle
    }

    var isToday: Bool {
        model.date == today
    }

    var memoText: String {
        let firstLine = model.memo.split(whereSeparator: \.isNewline).first

        return firstLine.map(String.init) ?? "＋ \(model.memoHint)"
    }
}
