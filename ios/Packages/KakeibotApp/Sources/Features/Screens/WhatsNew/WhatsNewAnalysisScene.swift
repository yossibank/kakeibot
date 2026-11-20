import DesignSystem
import SwiftUI

struct WhatsNewAnalysisScene: View {
    let kind: WhatsNewScene.Kind

    var body: some View {
        switch kind {
        case .analysisReason:
            reason

        case .analysisSummary:
            summary

        default:
            displaySwitch
                .whatsNewTapped()
        }
    }
}

private extension WhatsNewAnalysisScene {
    struct Metric {
        let title: String
        let previous: CGFloat
        let current: CGFloat
        let isUp: Bool
    }

    static let metrics = [
        Metric(title: "回数", previous: 0.6, current: 1, isUp: true),
        Metric(title: "1 回", previous: 0.9, current: 0.85, isUp: false)
    ]

    var displaySwitch: some View {
        HStack(spacing: 4) {
            segment("グラフ", systemImage: "chart.pie", isSelected: false)
            segment("分析", systemImage: "sparkles", isSelected: true)
        }
        .padding(4)
        .background(Palette.accent.opacity(.faint), in: .rect(cornerRadius: 12))
        .padding(4)
        .background(Palette.card, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Palette.accent.opacity(.medium))
        }
        .padding(.horizontal, 4)
    }

    var reason: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("いちばん増えたカテゴリ")
                .textFont(size: .micro)
                .foregroundStyle(Palette.subtext)

            HStack(alignment: .firstTextBaseline) {
                Text("食費")
                    .textFont(size: .small, weight: .bold)
                    .foregroundStyle(Palette.text)

                Spacer(minLength: 4)

                Text("+18%")
                    .displayFont(.headline, weight: .bold)
                    .foregroundStyle(Palette.increase)
            }

            HStack(alignment: .bottom, spacing: 12) {
                ForEach(Self.metrics, id: \.title) { metric in
                    bars(metric)
                }
            }
        }
        .monospacedDigit()
        .padding(8)
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }

    var summary: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "sparkle")
                    .textFont(size: .micro, weight: .bold)
                    .foregroundStyle(Palette.backgroundBottom)
                    .frame(width: 18, height: 18)
                    .background(Palette.gold, in: Circle())

                Text("AI のまとめ")
                    .textFont(size: .micro, weight: .bold)
                    .tracking(1)
                    .foregroundStyle(Palette.accent)
            }

            Text("外食の回数が増えて、食費が先月より多くなりました")
                .textFont(size: .caption, weight: .semibold)
                .foregroundStyle(Palette.text)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(8)
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }

    func segment(
        _ title: String,
        systemImage: String,
        isSelected: Bool
    ) -> some View {
        HStack(spacing: 2) {
            Image(systemName: systemImage)

            Text(title)
        }
        .textFont(size: .caption, weight: .bold)
        .foregroundStyle(isSelected ? Palette.backgroundBottom : Palette.subtext)
        .frame(maxWidth: .infinity)
        .frame(height: 32)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Palette.gold)
            }
        }
    }

    func bars(_ metric: Metric) -> some View {
        let fill = metric.isUp ? AnyShapeStyle(Palette.increase) : AnyShapeStyle(Palette.gold)

        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .bottom, spacing: 4) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Palette.accent.opacity(.soft))
                    .frame(width: 12, height: 28 * metric.previous)

                RoundedRectangle(cornerRadius: 2)
                    .fill(fill)
                    .frame(width: 12, height: 28 * metric.current)
            }
            .frame(height: 28, alignment: .bottom)

            Text(metric.title)
                .textFont(size: .micro)
                .foregroundStyle(Palette.subtext)
        }
    }
}
