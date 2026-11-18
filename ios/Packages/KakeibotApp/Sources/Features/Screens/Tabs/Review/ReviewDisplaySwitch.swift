import Core
import DesignSystem
import SwiftUI

struct ReviewDisplaySwitch: View {
    @Namespace private var selection

    let display: ReviewModel.Display
    let state: ReviewModel.CommentState
    let onSelect: (ReviewModel.Display) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                segment(.chart)
                segment(.analysis)
            }
            .padding(4)
            .background(Palette.accent.opacity(.faint), in: .rect(cornerRadius: 16))

            if display == .chart,
               let teaser {
                Rectangle()
                    .fill(Self.divider)
                    .frame(height: 1)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)

                Button {
                    onSelect(.analysis)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkle")
                            .sansFont(.caption, weight: .bold)
                            .foregroundStyle(Palette.accent)
                            .frame(width: 28, height: 28)
                            .background(Palette.accent.opacity(.subtle), in: Circle())

                        Text(teaser)
                            .displayFont(.small, weight: .semibold)
                            .foregroundStyle(Palette.text)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Image(systemName: "chevron.right")
                            .sansFont(.caption, weight: .semibold)
                            .foregroundStyle(Palette.accent)
                    }
                    .padding(.horizontal, 8)
                    .frame(minHeight: 48)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Palette.card, in: .rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Self.edge)
        }
        .shadow(color: Palette.accent.opacity(.subtle), radius: 12, y: 8)
        .animation(.snappy, value: display)
    }
}

private extension ReviewDisplaySwitch {
    func segment(_ item: ReviewModel.Display) -> some View {
        let isSelected = item == display
        let color = isSelected ? Palette.backgroundBottom : Palette.subtext
        let iconColor = isSelected ? Palette.backgroundBottom : Self.iconColor(of: item)
        let weight: Font.Weight = isSelected ? .bold : .medium
        let showsDot = item == .analysis && !isSelected && Self.isReady(state)

        return Button {
            onSelect(item)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: Self.symbol(of: item))
                    .sansFont(.small, weight: .semibold)
                    .foregroundStyle(iconColor)

                Text(Self.title(of: item))
                    .textFont(.subheadline, weight: weight)

                if showsDot {
                    Circle()
                        .fill(Palette.rose)
                        .frame(width: 6, height: 6)
                        .background {
                            Circle()
                                .fill(Palette.rose.opacity(.soft))
                                .frame(width: 12, height: 12)
                        }
                }
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Palette.gold)
                        .shadow(color: Palette.accentDeep.opacity(.muted), radius: 8, y: 4)
                        .matchedGeometryEffect(id: "selection", in: selection)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private extension ReviewDisplaySwitch {
    static var divider: LinearGradient {
        LinearGradient(
            colors: [
                Palette.accent.opacity(0),
                Palette.accent.opacity(.medium),
                Palette.accent.opacity(0)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var edge: LinearGradient {
        LinearGradient(
            colors: [
                Palette.accent.opacity(.medium),
                Palette.accent.opacity(.subtle),
                Palette.accent.opacity(.medium)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var teaser: String? {
        switch state {
        case .hidden, .failed: nil
        case .loading: "記録を分析しています"
        case let .ready(comment): comment.headline
        case let .needsRecords(count): "あと \(ReviewComment.minimumEntries - count) 件で分析できます"
        }
    }

    static func iconColor(of item: ReviewModel.Display) -> Color {
        switch item {
        case .chart: Palette.subtext
        case .analysis: Palette.accent
        }
    }

    static func isReady(_ state: ReviewModel.CommentState) -> Bool {
        if case .ready = state {
            return true
        }

        return false
    }

    static func symbol(of item: ReviewModel.Display) -> String {
        switch item {
        case .chart: "chart.pie"
        case .analysis: "sparkles"
        }
    }

    static func title(of item: ReviewModel.Display) -> String {
        switch item {
        case .chart: "グラフ"
        case .analysis: "分析"
        }
    }
}
