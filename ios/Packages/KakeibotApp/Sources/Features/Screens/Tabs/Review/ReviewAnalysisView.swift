import Core
import DesignSystem
import SwiftUI

struct ReviewAnalysisView: View {
    let state: ReviewModel.CommentState
    let note: String
    let unit: String
    let currentName: String
    let onRewrite: () -> Void
    let onRecord: () -> Void

    var body: some View {
        switch state {
        case .hidden:
            EmptyView()

        case .loading:
            hero {
                loading
            }

        case let .ready(comment):
            ready(comment)

        case let .needsRecords(count):
            hero {
                needsRecords(count)
            }

        case .failed:
            hero {
                failed
            }
        }
    }
}

private extension ReviewAnalysisView {
    var frameMark: some View {
        Image(systemName: "sparkle")
            .sansFont(.small, weight: .bold)
            .foregroundStyle(Palette.accent)
    }

    func action(_ comment: ReviewComment) -> some View {
        Group {
            if let action = comment.breakdown?.action {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("次の一手")
                            .displayFont(.small, weight: .bold)
                            .tracking(1)
                            .opacity(0.8)

                        Text(action.lead)
                            .textFont(.footnote)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(ReviewInsight.yen(action.amount))
                            .displayFont(.title, weight: .bold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)

                        Text("ほど浮きます")
                            .textFont(.caption)
                            .opacity(0.8)
                    }
                    .layoutPriority(1)
                }
                .foregroundStyle(Palette.backgroundBottom)
                .padding(20)
                .background {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Palette.gold)
                        .overlay {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Self.sheen)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 24)
                                .strokeBorder(Color.white.opacity(.soft))
                        }
                        .shadow(color: Palette.accentDeep.opacity(.muted), radius: 16, y: 10)
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "lightbulb")
                        .foregroundStyle(Palette.accent)

                    Text(comment.suggestion)
                        .textFont(.footnote)
                        .foregroundStyle(Palette.accentStrong)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
                .card()
            }
        }
    }

    func goodPoint(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .sansFont(.micro, weight: .bold)
                .foregroundStyle(Palette.backgroundBottom)
                .frame(width: 20, height: 20)
                .background(Palette.accent, in: Circle())

            Text(text)
                .textFont(.footnote)
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.accent.opacity(.faint), in: .rect(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Palette.accent.opacity(.subtle))
        }
    }

    func hero(@ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(note)
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            content()
        }
        .foregroundStyle(Palette.text)
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Palette.card)

                RoundedRectangle(cornerRadius: 24)
                    .fill(Self.glow)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(Self.goldEdge)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Palette.accent.opacity(.medium), lineWidth: 0.5)
                    .padding(8)
            }
            .overlay(alignment: .top) {
                frameMark
                    .offset(y: -6)
            }
            .overlay(alignment: .bottom) {
                frameMark
                    .offset(y: 6)
            }
            .shadow(color: Palette.accent.opacity(.soft), radius: 20, y: 12)
        }
    }

    func ready(_ comment: ReviewComment) -> some View {
        VStack(spacing: 12) {
            hero {
                VStack(alignment: .leading, spacing: 8) {
                    Text("“")
                        .displayFont(.display, weight: .bold)
                        .foregroundStyle(Palette.accent)
                        .frame(height: 20, alignment: .top)

                    Text(highlighted(comment))
                        .displayFont(.headline, weight: .semibold)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)

                    if let point = comment.breakdown?.goodPoint {
                        goodPoint(point)
                            .padding(.top, 4)
                    }
                }
            }

            if let summary = comment.breakdown {
                focus(summary.focus)

                if !summary.rows.isEmpty {
                    memo(summary.rows)
                }
            }

            action(comment)

            rewriteButton
                .padding(.top, 4)
        }
    }
}

extension ReviewAnalysisView {
    static var fadingLine: LinearGradient {
        LinearGradient(
            colors: [Palette.accent.opacity(.muted), Palette.accent.opacity(0)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var rewriteButton: some View {
        Button(action: onRewrite) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.clockwise")
                    .sansFont(.small, weight: .bold)
                    .foregroundStyle(Palette.backgroundBottom)
                    .frame(width: 40, height: 40)
                    .background(Palette.gold, in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(Color.white.opacity(.soft))
                    }

                Text("分析し直す")
                    .displayFont(.small, weight: .bold)
                    .foregroundStyle(Palette.accentStrong)
            }
            .padding(.leading, 4)
            .padding(.trailing, 24)
            .frame(minHeight: 48)
            .background(Self.buttonFill, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(Self.goldEdge)
            }
            .shadow(color: Palette.accentDeep.opacity(.soft), radius: 10, y: 6)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    func sectionTitle(
        _ number: String,
        _ title: String
    ) -> some View {
        HStack(spacing: 8) {
            Text(number)
                .displayFont(.headline, weight: .bold)
                .foregroundStyle(Palette.accent)

            Text(title)
                .textFont(.subheadline, weight: .bold)
                .foregroundStyle(Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Rectangle()
                .fill(Self.fadingLine)
                .frame(height: 1)
        }
    }
}

private extension ReviewAnalysisView {
    static var buttonFill: LinearGradient {
        LinearGradient(
            colors: [Palette.cardTop, Palette.accent.opacity(.subtle)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var glow: RadialGradient {
        RadialGradient(
            colors: [Palette.accent.opacity(.soft), Palette.accent.opacity(0)],
            center: .topLeading,
            startRadius: 0,
            endRadius: 280
        )
    }

    static var goldEdge: LinearGradient {
        LinearGradient(
            colors: [
                Palette.accent,
                Palette.accent.opacity(.subtle),
                Palette.accent.opacity(.medium)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var sheen: LinearGradient {
        LinearGradient(
            stops: [
                Gradient.Stop(color: Color.white.opacity(0), location: 0.3),
                Gradient.Stop(color: Color.white.opacity(.soft), location: 0.42),
                Gradient.Stop(color: Color.white.opacity(0), location: 0.54)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func highlighted(_ comment: ReviewComment) -> AttributedString {
        var text = AttributedString(comment.body)

        for match in comment.body.matches(of: #/([0-9]+)%/#) {
            let isIncrease = comment.basis.contains("\(match.output.1)% 増")

            guard
                isIncrease,
                let range = text.range(of: String(match.output.0))
            else {
                continue
            }

            text[range].foregroundColor = Palette.increase
        }

        return text
    }
}

#Preview {
    let comment = ReviewComment(
        period: "month:2026-11-01",
        body: "食費が増えたのは、回数が 8 回増えたためです。1 回の額は前の月と変わりません。",
        suggestion: "食費を前の月と同じ 20 回ほどに戻すと、11,200円 ほど浮きます。",
        basis: "",
        createdAt: Date()
    )

    ScrollView {
        ReviewAnalysisView(
            state: .ready(comment),
            note: "11/1–11/18 · 42 件",
            unit: "月",
            currentName: "今月",
            onRewrite: {},
            onRecord: {}
        )
        .padding(16)
    }
}
