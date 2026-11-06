import Core
import DesignSystem
import SwiftUI

extension ReviewView {
    func moveCard(_ moves: [ReviewModel.Move]) -> some View {
        let total = ReviewModel.total(of: moves)
        let ratio = model.repaymentRatio(in: moves)
        let repaidPercent = Int((ratio * 100).rounded())

        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                CardHeader("返済と積立", systemImage: "arrow.left.arrow.right") {
                    AmountText(total, font: .size(.headline), color: Palette.accentStrong)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }

                Text("支出には数えていません")
                    .textFont(.caption2)
                    .foregroundStyle(Palette.hint)
            }

            VStack(spacing: 8) {
                SplitBar(
                    ratio,
                    leading: Palette.accent,
                    trailing: Palette.accent.opacity(.medium)
                )

                HStack {
                    moveLegend(
                        "返済",
                        percent: repaidPercent,
                        color: Palette.accent
                    )

                    Spacer()

                    moveLegend(
                        "積立",
                        percent: 100 - repaidPercent,
                        color: Palette.accent.opacity(.medium)
                    )
                }
            }

            VStack(spacing: 0) {
                ForEach(moves) { move in
                    Button {
                        openShare = model.share(of: move)
                    } label: {
                        moveRow(move)
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .top) {
                        Hairline(thickness: 1)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .sharesTextScale(id: moves.map(\.wallet.name))
    }
}

private extension ReviewView {
    func moveLegend(
        _ title: String,
        percent: Int,
        color: Color
    ) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text("\(title) \(percent)%")
                .textFont(.caption2)
                .monospacedDigit()
                .foregroundStyle(Palette.subtext)
        }
    }

    func moveRow(_ move: ReviewModel.Move) -> some View {
        HStack(spacing: 12) {
            IconBadge(move.icon, size: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(move.wallet.name)
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.text)
                    .sharedTextScale()

                if let note = Self.moveNote(of: move) {
                    Text(note)
                        .textFont(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }

            Spacer(minLength: 8)

            AmountText(move.amount, font: .style(.subheadline), color: Palette.accentStrong)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Image(systemName: "chevron.right")
                .sansFont(.small)
                .foregroundStyle(Palette.hint)
        }
        .padding(.vertical, 8)
        .contentShape(.rect)
    }
}

private extension ReviewView {
    static func moveNote(of move: ReviewModel.Move) -> String? {
        guard move.wallet.archivedAt == nil else {
            return nil
        }

        let balance = AmountText.text(abs(move.balance))

        guard move.wallet.kind == .loan else {
            return "評価額 \(balance)"
        }

        guard move.balance < 0 else {
            return "返し終わりました"
        }

        guard let payoff = move.payoff else {
            return "残り \(balance)"
        }

        return "残り \(balance)・あと \(payoff.count) 回"
    }
}
