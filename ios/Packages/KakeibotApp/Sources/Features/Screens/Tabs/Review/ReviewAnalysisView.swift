import Core
import DesignSystem
import SwiftUI

struct ReviewAnalysisView: View {
    @State var hasAppeared = false

    let state: ReviewModel.CommentState
    let note: String
    let unit: String
    let currentName: String
    let entryCount: Int
    let focusName: String?
    let months: [ReviewModel.MonthAmount]
    let isNew: Bool
    let newEntries: Int
    let onRewrite: () -> Void
    let onRecord: () -> Void
    let onOpen: (ReviewModel.Factor) -> Void

    var body: some View {
        switch state {
        case .hidden:
            EmptyView()

        case .loading:
            hero(showsHeader: false) {
                loading
            }

        case let .ready(comment):
            ready(comment)
                .onAppear {
                    withAnimation(.smooth(duration: 0.9).delay(0.15)) {
                        hasAppeared = true
                    }
                }

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

extension ReviewAnalysisView {
    static var goldEdge: LinearGradient {
        LinearGradient(
            colors: [
                Palette.accent.opacity(.medium),
                Palette.accent.opacity(.subtle),
                Palette.accent.opacity(.muted)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var fadingLine: LinearGradient {
        LinearGradient(
            colors: [Palette.accent.opacity(.medium), Palette.accent.opacity(0)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    func panel(@ViewBuilder content: () -> some View) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.card, in: .rect(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Palette.accent.opacity(.soft))
            }
    }

    func panelTitle(_ title: String) -> some View {
        Text(title)
            .textFont(.subheadline, weight: .bold)
            .foregroundStyle(Palette.text)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    func suggestion(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "lightbulb")
                .foregroundStyle(Palette.accent)

            Text(text)
                .textFont(.footnote)
                .foregroundStyle(Palette.accentStrong)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .card(cornerRadius: 20)
    }
}

private extension ReviewAnalysisView {
    var badge: some View {
        Image(systemName: "chart.bar.fill")
            .sansFont(.caption, weight: .bold)
            .foregroundStyle(Palette.backgroundBottom)
            .frame(width: 28, height: 28)
            .background(Palette.gold, in: .rect(cornerRadius: 8))
            .shadow(color: Palette.accent.opacity(.soft), radius: 4)
    }

    var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                badge

                Text("分析レポート")
                    .textFont(.subheadline, weight: .bold)
                    .tracking(0.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if isNew,
                   case .ready = state {
                    Text("NEW")
                        .textFont(.caption2, weight: .bold)
                        .tracking(1)
                        .foregroundStyle(Palette.backgroundBottom)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Palette.gold, in: Capsule())
                        .fixedSize()
                }

                Spacer(minLength: 8)

                Text(note)
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Rectangle()
                .fill(Self.fadingLine)
                .frame(height: 1)
        }
    }

    func hero(
        showsHeader: Bool = true,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if showsHeader {
                header
            }

            content()
        }
        .foregroundStyle(Palette.text)
        .padding(20)
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
            .shadow(color: Palette.accent.opacity(.subtle), radius: 16, y: 12)
        }
    }

    func ready(_ comment: ReviewComment) -> some View {
        VStack(spacing: 12) {
            hero {
                if let summary = comment.breakdown {
                    headline(summary.focus)
                } else {
                    quote(comment)
                }
            }

            if let summary = comment.breakdown {
                if summary.focus.hasPrevious,
                   summary.focus.amount > summary.focus.previousAmount {
                    waterfall(summary.focus)
                } else if months.count >= 2 {
                    monthChart(summary.focus.name)
                }

                quote(comment)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Self.quoteFill, in: .rect(cornerRadius: 20))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Palette.accent.opacity(.muted))
                    }

                metrics(summary.focus)

                if !summary.rows.isEmpty {
                    memo(summary.rows)
                }

                action(summary, suggestion: comment.suggestion)
            } else {
                suggestion(comment.suggestion)
            }

            rewriteButton(since: comment.createdAt)
                .padding(.top, 4)
        }
    }

    func quote(_ comment: ReviewComment) -> some View {
        let sentences = Self.sentences(of: comment.body)
        let rest = sentences.dropFirst().joined()

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sparkle")
                    .sansFont(.caption, weight: .bold)
                    .foregroundStyle(Palette.backgroundBottom)
                    .frame(width: 24, height: 24)
                    .background(Palette.gold, in: Circle())
                    .shadow(color: Palette.accent.opacity(.soft), radius: 3)

                Text("AI のまとめ")
                    .textFont(.caption2, weight: .bold)
                    .tracking(1.5)
                    .foregroundStyle(Palette.accent)
            }

            Text(highlighted(sentences.first ?? comment.body, in: comment))
                .displayFont(.headline, weight: .bold)
                .foregroundStyle(Palette.text)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            if !rest.isEmpty {
                Text(rest)
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let point = comment.breakdown?.goodPoint {
                goodPoint(point)
            }
        }
    }

    func goodPoint(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle()
                .fill(Palette.accent.opacity(.soft))
                .frame(height: 1)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "checkmark")
                    .sansFont(.micro, weight: .bold)
                    .foregroundStyle(Palette.accent)

                Text(text)
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 4)
    }
}

private extension ReviewAnalysisView {
    static var glow: RadialGradient {
        RadialGradient(
            colors: [Palette.accent.opacity(.subtle), Palette.accent.opacity(0)],
            center: .topTrailing,
            startRadius: 0,
            endRadius: 260
        )
    }

    static var quoteFill: LinearGradient {
        LinearGradient(
            colors: [Palette.accent.opacity(.subtle), Palette.accent.opacity(.faint)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func sentences(of text: String) -> [String] {
        text
            .split(separator: "。", omittingEmptySubsequences: true)
            .map { "\($0)。" }
    }

    func highlighted(
        _ sentence: String,
        in comment: ReviewComment
    ) -> AttributedString {
        var text = AttributedString(sentence)
        let focus = comment.breakdown?.focus
        let isUp = focus.map { $0.hasPrevious && $0.amount > $0.previousAmount } ?? false

        if let name = focus?.name,
           let range = text.range(of: name) {
            text[range].foregroundColor = Palette.accent
        }

        for match in sentence.matches(of: #/[0-9][0-9,]*\s?(回|円|%)/#) {
            let number = String(match.output.0)
            let isIncrease = isUp || comment.basis.contains("\(number) 増")

            guard
                isIncrease,
                let range = text.range(of: number)
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
        body: "食費が増えたのは、回数が 8 回増えたためです。1 回の金額は前の月と変わりません。",
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
            entryCount: 42,
            focusName: "食費",
            months: [],
            isNew: true,
            newEntries: 3,
            onRewrite: {},
            onRecord: {},
            onOpen: { _ in }
        )
        .padding(16)
    }
}
