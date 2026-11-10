import Core
import DesignSystem
import SwiftUI

struct WhatsNewOutlookScene: View {
    let kind: WhatsNewScene.Kind

    var body: some View {
        switch kind {
        case .outlookBlock:
            block
                .whatsNewTapped()

        case .outlookList:
            list

        default:
            WhatsNewPlanScene(kind: .planTab)
        }
    }
}

private extension WhatsNewOutlookScene {
    struct Move {
        let day: String
        let name: String
        let amount: Int
    }

    static let onHand = 182_400

    static let moves = [
        Move(day: "11/25", name: "給料", amount: 248_000),
        Move(day: "11/27", name: "カード", amount: -32400),
        Move(day: "11/30", name: "家賃", amount: -85000)
    ]

    static var income: Int {
        moves.map(\.amount).filter { $0 > 0 }.reduce(0, +)
    }

    static var expense: Int {
        moves.map(\.amount).filter { $0 < 0 }.reduce(0, +)
    }

    static var outlook: Int {
        onHand + income + expense
    }

    var block: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("今月これから", systemImage: "calendar")
                .textFont(size: .micro, weight: .semibold)
                .foregroundStyle(Palette.subtext)

            totalRow("入る", amount: Self.income, color: Palette.accentStrong)

            totalRow("出る", amount: Self.expense, color: Palette.text)

            Rectangle()
                .fill(Palette.hairline)
                .frame(height: 1)

            Text("月末の見込み")
                .textFont(size: .micro, weight: .semibold)
                .foregroundStyle(Palette.subtext)

            HStack(spacing: 2) {
                Spacer(minLength: 2)

                AmountText(Self.outlook, font: .size(.caption, weight: .bold), color: Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Image(systemName: "chevron.right")
                    .textFont(size: .micro, weight: .semibold)
                    .foregroundStyle(Palette.hint)
            }
        }
        .monospacedDigit()
        .padding(8)
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }

    var list: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("今月これからの出入り")
                .textFont(size: .micro, weight: .semibold)
                .tracking(1)
                .foregroundStyle(Palette.accent)

            ForEach(Self.moves, id: \.day) { move in
                moveRow(move)
            }
        }
        .monospacedDigit()
        .padding(8)
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }

    func totalRow(
        _ label: String,
        amount: Int,
        color: Color
    ) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundStyle(Palette.subtext)

            Spacer(minLength: 2)

            AmountText(amount, font: .size(.micro, weight: .semibold), color: color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .textFont(size: .micro, weight: .semibold)
    }

    func moveRow(_ move: Move) -> some View {
        let color = move.amount > 0 ? Palette.accentStrong : Palette.text

        return HStack(spacing: 4) {
            Text(move.day)
                .foregroundStyle(Palette.subtext)

            Text(move.name)
                .foregroundStyle(Palette.text)

            Spacer(minLength: 2)

            AmountText(move.amount, font: .size(.micro, weight: .semibold), color: color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .textFont(size: .micro, weight: .semibold)
        .frame(height: 20)
    }
}
