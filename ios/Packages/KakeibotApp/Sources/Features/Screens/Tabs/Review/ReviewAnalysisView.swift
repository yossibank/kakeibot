import Core
import DesignSystem
import SwiftUI

struct ReviewAnalysisView: View {
    @State var hasAppeared = false

    let state: ReviewModel.CommentState
    let unit: String
    let currentName: String
    let entryCount: Int
    let focusName: String?
    let months: [ReviewModel.MonthAmount]
    let categories: [String]
    let previousSpan: String
    let currentSpan: String
    let isNew: Bool
    let onRetry: () -> Void
    let onRecord: () -> Void
    let onOpen: (ReviewModel.Factor) -> Void
    let onOpenCategory: (String) -> Void

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
    func hero(@ViewBuilder content: () -> some View) -> some View {
        content()
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
                quote(comment)
            }

            if let summary = comment.breakdown {
                compare(summary.focus)

                if !summary.focus.hasPrevious,
                   months.count >= 2 {
                    monthChart(summary.focus.name)
                }

                if !summary.rows.isEmpty {
                    memo(summary.rows)
                }

                action(summary, suggestion: comment.suggestion)
            } else {
                suggestion(comment.suggestion)
            }

            Text(Self.madeText(comment.createdAt))
                .textFont(.caption2)
                .foregroundStyle(Palette.hint)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
        }
    }

    func quote(_ comment: ReviewComment) -> some View {
        let body = ReviewComment.normalizedNumbers(comment.body)
        let point = comment.breakdown?.goodPoint
        let focus = comment.breakdown?.focus.rising
        let sentences = Self.sentences(of: body)
        let rest = sentences.dropFirst().filter { !repeats($0, in: point) }.joined()

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

                Spacer(minLength: 8)

                if isNew {
                    Text("NEW")
                        .textFont(.caption2, weight: .bold)
                        .tracking(1)
                        .foregroundStyle(Palette.backgroundBottom)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Palette.gold, in: Capsule())
                        .fixedSize()
                }
            }

            if let focus {
                headline(focus)
            }

            Text(linked(highlighted(sentences.first ?? body, in: comment)))
                .displayFont(.headline, weight: .bold)
                .foregroundStyle(Palette.text)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            if !rest.isEmpty {
                Text(linked(AttributedString(rest)))
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let focus {
                reasonChips(focus)
            }

            if let point {
                goodPoint(point)
            }
        }
        .tint(Palette.accent)
        .environment(\.openURL, OpenURLAction(handler: openCategory))
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

                Text(linked(AttributedString(text)))
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 4)
    }
}

private extension ReviewAnalysisView {
    static let categoryScheme = "kakeibot-category"

    static var glow: RadialGradient {
        RadialGradient(
            colors: [Palette.accent.opacity(.subtle), Palette.accent.opacity(0)],
            center: .topTrailing,
            startRadius: 0,
            endRadius: 260
        )
    }

    static func madeText(_ date: Date) -> String {
        let made = date.formatted(.dateTime.month(.defaultDigits).day().hour().minute())
        return "記録が変わると、次に開いた時に新しくなります · \(made)"
    }

    static func sentences(of text: String) -> [String] {
        text
            .split(separator: "。", omittingEmptySubsequences: true)
            .map { "\($0)。" }
    }

    static func categoryURL(of name: String) -> URL? {
        var components = URLComponents()
        components.scheme = categoryScheme
        components.host = "open"
        components.queryItems = [URLQueryItem(name: "name", value: name)]
        return components.url
    }

    func repeats(
        _ sentence: String,
        in point: String?
    ) -> Bool {
        guard let point else {
            return false
        }

        let numbers = ReviewComment.numbers(in: sentence)

        guard
            !numbers.isEmpty,
            numbers == ReviewComment.numbers(in: point)
        else {
            return false
        }

        return categories.contains { sentence.contains($0) && point.contains($0) }
    }

    func highlighted(
        _ sentence: String,
        in comment: ReviewComment
    ) -> AttributedString {
        var text = AttributedString(sentence)
        let increased = comment.increasedNumbers

        for match in sentence.matches(of: #/[0-9][0-9,]*\s?(回|円|%)/#) {
            let number = String(match.output.0)

            guard
                !ReviewComment.numbers(in: number).isDisjoint(with: increased),
                let range = text.range(of: number)
            else {
                continue
            }

            text[range].foregroundColor = Palette.increase
        }

        return text
    }

    func linked(_ text: AttributedString) -> AttributedString {
        var text = text
        let names = categories.sorted { $0.count > $1.count }

        for name in names {
            guard let url = Self.categoryURL(of: name) else {
                continue
            }

            var start = text.startIndex

            while let range = text[start...].range(of: name) {
                if text[range].link == nil {
                    text[range].link = url
                    text[range].foregroundColor = Palette.accent
                }

                start = range.upperBound
            }
        }

        return text
    }

    func openCategory(_ url: URL) -> OpenURLAction.Result {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        guard
            components?.scheme == Self.categoryScheme,
            let name = components?.queryItems?.first?.value
        else {
            return .systemAction
        }

        onOpenCategory(name)
        return .handled
    }
}

#Preview {
    let comment = ReviewComment(
        period: "month:2026-11-01",
        body: "食費が増えたのは、回数が 8 回増えたためです。1 回の金額は前の月と変わりません。",
        suggestion: "食費を前の月と同じ 20 回ほどに戻すと、11,200円 浮きます。",
        basis: "",
        createdAt: Date()
    )

    ScrollView {
        ReviewAnalysisView(
            state: .ready(comment),
            unit: "月",
            currentName: "今月",
            entryCount: 42,
            focusName: "食費",
            months: [],
            categories: ["食費"],
            previousSpan: "10/1〜10/18",
            currentSpan: "11/1〜11/18",
            isNew: true,
            onRetry: {},
            onRecord: {},
            onOpen: { _ in },
            onOpenCategory: { _ in }
        )
        .padding(16)
    }
}
