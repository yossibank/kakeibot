import Core
import DesignSystem
import SwiftUI

struct WhatsNewPlanScene: View {
    let kind: WhatsNewScene.Kind

    var body: some View {
        switch kind {
        case .planButton:
            planButton
                .whatsNewTapped()

        case .planList:
            planList

        default:
            tabBar
                .whatsNewTapped()
        }
    }
}

private extension WhatsNewPlanScene {
    struct Plan {
        let day: String
        let name: String
        let amount: Int
    }

    static let onHand = 182_400

    static let plans = [
        Plan(day: "11/25", name: "給料", amount: 248_000),
        Plan(day: "11/27", name: "カード", amount: -32400),
        Plan(day: "11/30", name: "家賃", amount: -85000)
    ]

    static var plannedTotal: Int {
        onHand + plans.map(\.amount).reduce(0, +)
    }

    var tabBar: some View {
        HStack(spacing: 4) {
            tab("ホーム", systemImage: "house", isSelected: false)
            tab("記録", systemImage: "calendar", isSelected: false)
            tab("資産", systemImage: "building.columns", isSelected: true)
        }
        .padding(4)
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }

    var planButton: some View {
        let shape = RoundedRectangle(cornerRadius: 8)

        return VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("手持ち")
                    .textFont(size: .micro)
                    .foregroundStyle(Palette.subtext)

                AmountText(Self.onHand, font: .size(.caption, weight: .bold), color: Palette.text)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("予定を含めると \(Self.plans.count) 件")
                    .textFont(size: .micro)
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                AmountText(
                    Self.plannedTotal,
                    font: .size(.caption, weight: .bold),
                    color: Palette.accentStrong
                )
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 40)
            .background(Palette.faint, in: shape)
            .overlay {
                shape
                    .stroke(
                        Palette.accent.opacity(.muted),
                        style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                    )
            }
        }
        .monospacedDigit()
        .padding(8)
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }

    var planList: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("予定の記録")
                .textFont(size: .micro, weight: .semibold)
                .tracking(1)
                .foregroundStyle(Palette.accent)

            ForEach(Self.plans, id: \.day) { plan in
                planRow(plan)
            }
        }
        .monospacedDigit()
        .padding(8)
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }

    func tab(
        _ title: String,
        systemImage: String,
        isSelected: Bool
    ) -> some View {
        let color = isSelected ? Palette.accentStrong : Palette.hint
        let fill = isSelected ? Palette.accent.opacity(.subtle) : Color.clear

        return VStack(spacing: 2) {
            Image(systemName: systemImage)
                .textFont(size: .small, weight: .semibold)

            Text(title)
                .textFont(size: .micro, weight: .semibold)
        }
        .foregroundStyle(color)
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .background(fill, in: .rect(cornerRadius: 8))
    }

    func planRow(_ plan: Plan) -> some View {
        let color = plan.amount > 0 ? Palette.accentStrong : Palette.text

        return HStack(spacing: 4) {
            Text(plan.day)
                .foregroundStyle(Palette.subtext)

            Text(plan.name)
                .foregroundStyle(Palette.text)

            Spacer(minLength: 2)

            AmountText(plan.amount, font: .size(.micro, weight: .semibold), color: color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .textFont(size: .micro, weight: .semibold)
        .frame(height: 20)
    }
}
