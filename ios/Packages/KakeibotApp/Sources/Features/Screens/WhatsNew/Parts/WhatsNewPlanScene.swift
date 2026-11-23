import Core
import DesignSystem
import SwiftUI

struct WhatsNewPlanScene: View {
    let step: Step

    var body: some View {
        switch step {
        case .button:
            planButton
                .whatsNewTapped()

        case .list:
            WhatsNewMoveList(title: "予定の記録")

        case .tab:
            tabBar
                .whatsNewTapped()
        }
    }
}

extension WhatsNewPlanScene {
    enum Step: Hashable, Sendable {
        case tab
        case button
        case list
    }
}

private extension WhatsNewPlanScene {
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

                AmountText(
                    WhatsNewMove.onHand,
                    font: .size(.caption, weight: .bold),
                    color: Palette.text
                )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("予定を含めると \(WhatsNewMove.samples.count) 件")
                    .textFont(size: .micro)
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                AmountText(
                    WhatsNewMove.outlook,
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
}
