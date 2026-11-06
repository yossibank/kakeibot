import Core
import DesignSystem
import SwiftUI

struct WhatsNewLoanScene: View {
    let kind: WhatsNewScene.Kind

    var body: some View {
        switch kind {
        case .loanFinal:
            finalAmount

        case .loanTotal:
            total

        default:
            countRow
                .whatsNewTapped()
        }
    }
}

private extension WhatsNewLoanScene {
    static let count = 36
    static let amount = 50000
    static let lastAmount = 12300

    var countRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "number")
                .foregroundStyle(Palette.accent)

            Text("回数")
                .foregroundStyle(Palette.text)

            Spacer(minLength: 4)

            Text("\(Self.count - 1) 回")
                .foregroundStyle(Palette.subtext)
        }
        .textFont(size: .caption, weight: .semibold)
        .padding(.horizontal, 12)
        .frame(height: 40)
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }

    var finalAmount: some View {
        VStack(spacing: 8) {
            Text("\(Self.count) 回")
                .displayFont(.headline, weight: .bold)
                .foregroundStyle(Palette.accentStrong)

            HStack {
                Text("最後の回")
                    .foregroundStyle(Palette.subtext)

                Spacer(minLength: 4)

                AmountText(
                    Self.lastAmount,
                    font: .size(.caption, weight: .semibold),
                    color: Palette.text
                )
            }
            .textFont(size: .caption, weight: .semibold)
        }
        .monospacedDigit()
        .padding(12)
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }

    var total: some View {
        let sum = Self.amount * (Self.count - 1) + Self.lastAmount

        return VStack(alignment: .leading, spacing: 4) {
            Text("返す総額")
                .textFont(size: .caption)
                .foregroundStyle(Palette.subtext)

            AmountText(sum, font: .size(.body, weight: .bold), color: Palette.accentStrong)

            Text("終わり 2029年10月")
                .textFont(size: .caption, weight: .semibold)
                .foregroundStyle(Palette.text)
        }
        .monospacedDigit()
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }
}
