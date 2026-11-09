import Core
import DesignSystem
import SwiftUI

extension AssetsView {
    func walletGroup(
        _ title: String,
        sections: [AssetsModel.WalletSection],
        addNote: String,
        onAdd: @escaping () -> Void
    ) -> some View {
        let rows = sections.flatMap(\.rows)
        let total = rows.reduce(0) { $0 + $1.balance }

        return VStack(alignment: .leading, spacing: 0) {
            CardHeader(title, note: rows.isEmpty ? nil : "\(rows.count) 口座")

            if rows.isEmpty {
                Text("口座を追加すると、ここに並びます")
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 8)
            } else {
                AmountText(
                    total,
                    font: .size(.title, weight: .bold),
                    color: Palette.accentStrong
                )
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.bottom, 4)
            }

            ForEach(sections) { section in
                walletSection(section)
                    .overlay(alignment: .top) {
                        Hairline(thickness: 1)
                    }
            }

            addWalletRow(note: addNote, action: onAdd)
                .overlay(alignment: .top) {
                    Hairline(thickness: 1)
                }
        }
        .padding(.horizontal, 16)
        .card()
    }
}

private extension AssetsView {
    func walletSection(_ section: AssetsModel.WalletSection) -> some View {
        let total = section.rows.reduce(0) { $0 + $1.balance }

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(Self.title(of: section.role))
                    .textFont(.caption, weight: .semibold)
                    .foregroundStyle(Palette.subtext)

                Spacer(minLength: 8)

                if section.rows.count > 1 {
                    AmountText(
                        total,
                        font: .style(.footnote, weight: .semibold),
                        color: Palette.subtext
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 4)

            ForEach(section.rows) { row in
                Button {
                    onOpenWallet(row.wallet.id)
                } label: {
                    walletRow(row)
                }
                .buttonStyle(.plain)
            }

            if section.role == .card {
                unpaidLink(of: section.rows)
            }
        }
        .padding(.bottom, 4)
        .sharesTextScale(id: section.rows.map(\.wallet.name))
    }

    func walletRow(_ row: AssetsModel.WalletRow) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    IconBadge(row.icon, size: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        walletLine(row)

                        debtDetail(of: row)
                    }
                    .frame(minHeight: 32)
                }

                Image(systemName: "chevron.right")
                    .sansFont(.small)
                    .foregroundStyle(Palette.hint)
            }

            if row.needsAdjustment {
                adjustNotice(of: row)
                    .padding(.leading, 44)
            }
        }
        .padding(.vertical, 8)
        .contentShape(.rect)
    }

    func walletLine(_ row: AssetsModel.WalletRow) -> some View {
        let label = Self.label(of: row)
        let nameWidth = label == nil ? Self.nameMinWidth : Self.labeledNameMinWidth

        return HStack(alignment: .firstTextBaseline, spacing: 8) {
            walletName(row)
                .frame(minWidth: nameWidth, alignment: .leading)

            Spacer(minLength: 0)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if let label {
                    walletLabel(label)
                }

                walletBalance(row)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .layoutPriority(1)
        }
    }

    func walletName(_ row: AssetsModel.WalletRow) -> some View {
        Text(row.wallet.name)
            .textFont(.subheadline)
            .foregroundStyle(Palette.text)
            .sharedTextScale()
    }

    func walletLabel(_ label: String) -> some View {
        Text(label)
            .textFont(.caption2)
            .foregroundStyle(Palette.subtext)
            .fixedSize()
    }

    func walletBalance(_ row: AssetsModel.WalletRow) -> some View {
        AmountText(
            row.balance,
            font: .style(.subheadline, weight: .semibold),
            color: Self.amountColor(of: row)
        )
    }

    func addWalletRow(
        note: String,
        action: @escaping () -> Void
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: corner.radius(32 * 0.3), style: .continuous)

        return Button(action: action) {
            HStack(spacing: 12) {
                shape
                    .fill(Palette.faint)
                    .overlay {
                        shape
                            .stroke(Palette.outline, style: .dashed)
                    }
                    .overlay {
                        Image(systemName: "plus")
                            .sansFont(.small, weight: .semibold)
                            .foregroundStyle(Palette.accent)
                    }
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text("新しい口座を追加")
                        .textFont(.subheadline, weight: .semibold)
                        .foregroundStyle(Palette.accentStrong)

                    Text(note)
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                }
                .lineLimit(1)

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .sansFont(.small)
                    .foregroundStyle(Palette.hint)
            }
            .padding(.vertical, 12)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    func adjustNotice(of row: AssetsModel.WalletRow) -> some View {
        let shape = RoundedRectangle(cornerRadius: corner.radius(12))

        return Button {
            adjusting = row
        } label: {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    adjustMessage(showsReason: true)

                    Spacer(minLength: 8)

                    adjustAction(fills: false)
                }

                HStack(spacing: 8) {
                    adjustMessage(showsReason: false)

                    Spacer(minLength: 8)

                    adjustAction(fills: false)
                }

                VStack(alignment: .leading, spacing: 12) {
                    adjustMessage(showsReason: true)

                    adjustAction(fills: true)
                }
            }
            .padding(12)
            .background(Palette.rose.opacity(.faint), in: shape)
            .overlay {
                shape
                    .strokeBorder(Palette.rose.opacity(.soft), lineWidth: 1)
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
    }

    func adjustAction(fills: Bool) -> some View {
        Text("残高を合わせる")
            .textFont(.caption, weight: .bold)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .frame(maxWidth: fills ? .infinity : nil)
            .frame(height: 32)
            .goldFace()
    }

    func adjustMessage(showsReason: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .sansFont(.body)
                .foregroundStyle(Palette.rose)

            VStack(alignment: .leading, spacing: 4) {
                Text("手持ちがマイナスです")
                    .textFont(.caption, weight: .bold)
                    .foregroundStyle(Palette.rose)

                if showsReason {
                    Text("記録と手元のお金がずれています")
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    func unpaidLink(of rows: [AssetsModel.WalletRow]) -> some View {
        let count = rows.compactMap(\.unpaid).reduce(0) { $0 + $1.count }

        if count > 0 {
            Button {
                entrySheet = .unpaid(of: rows)
            } label: {
                HStack(spacing: 4) {
                    Label(
                        "未払いの記録を見る（\(count) 件）",
                        systemImage: "list.bullet"
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                    Image(systemName: "chevron.right")
                        .sansFont(.micro, weight: .bold)
                }
                .textFont(.caption2)
                .foregroundStyle(Palette.accent)
                .padding(.leading, 44)
                .padding(.vertical, 8)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }
}

private extension AssetsView {
    static let nameMinWidth: CGFloat = 64
    static let labeledNameMinWidth: CGFloat = 48

    @ViewBuilder
    func debtDetail(of row: AssetsModel.WalletRow) -> some View {
        let bills = row.bills.filter { $0.amount > 0 }

        if row.wallet.kind == .card,
           !bills.isEmpty {
            AssetsBillSchedule(bills: bills)
                .padding(.top, 4)
        }

        if let ratio = row.repaidRatio,
           let percent = row.repaidPercent {
            HStack(spacing: 8) {
                RatioBar(ratio, tint: Palette.accent)

                Text("\(percent)% 返した")
                    .textFont(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .fixedSize()
            }
        }

        if case let .until(payoff) = row.repayment {
            AssetsDebtChip(
                systemImage: "arrow.triangle.2.circlepath",
                text: Self.payoffText(payoff)
            )
        } else if let note = plainNote(of: row) {
            Text(note)
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    static func title(of role: Wallet.Kind.Role) -> String {
        switch role {
        case .onHand: "手持ち"
        case .card: "カードの未払い"
        case .investment: "投資"
        case .loan: "借入"
        }
    }

    static func label(of row: AssetsModel.WalletRow) -> String? {
        switch row.wallet.kind.role {
        case .card: row.balance > 0 ? "返ってくる額" : "未払い"
        case .loan: "残り"
        case .onHand, .investment: nil
        }
    }

    static func amountColor(of row: AssetsModel.WalletRow) -> Color {
        switch row.wallet.kind.role {
        case .card: row.balance > 0 ? Palette.accent : Palette.text

        case .loan: Palette.text

        case .onHand, .investment:
            row.balance < 0 ? Palette.rose : Palette.accentStrong
        }
    }

    static func repaymentText(_ repayment: AssetsModel.Repayment) -> String? {
        switch repayment {
        case .unset: "返済は未設定"
        case .finished: "返し終わりました"
        case .open: "返し終わる時期は未定"
        case .until: nil
        }
    }

    static func payoffText(_ payoff: LoanPayoff) -> String {
        let date = payoff.lastDate
        return "あと \(payoff.count) 回 · \(String(date.year))/\(date.month) まで"
    }

    func plainNote(of row: AssetsModel.WalletRow) -> String? {
        if let repayment = row.repayment {
            return Self.repaymentText(repayment)
        }

        guard
            row.wallet.kind == .card,
            row.bills.isEmpty
        else {
            return nil
        }

        return "引き落としは未設定"
    }
}
