import Core
import DesignSystem
import SwiftUI

struct ReviewCommentCard: View {
    let state: ReviewModel.CommentState
    let title: String
    let until: LocalDate
    let onRewrite: () -> Void
    let onRecord: () -> Void
    let onFold: (Bool) -> Void

    var body: some View {
        if state == .folded {
            folded
        } else {
            VStack(alignment: .leading, spacing: 12) {
                ViewThatFits(in: .horizontal) {
                    header(note: "\(untilText)までの記録から")
                    header(note: "\(untilText)まで")
                    header(note: nil)
                }

                switch state {
                case .hidden, .folded:
                    EmptyView()

                case .loading:
                    loading

                case let .ready(comment):
                    ready(comment)

                case let .needsRecords(count):
                    needsRecords(count)

                case .failed:
                    failed
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()
        }
    }
}

private extension ReviewCommentCard {
    var loading: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ひとことを書いています")
                .textFont(.footnote)
                .foregroundStyle(Palette.subtext)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Self.barInsets, id: \.self) { inset in
                    Capsule()
                        .fill(Palette.line)
                        .frame(height: 12)
                        .padding(.trailing, inset)
                }
            }
        }
    }

    var folded: some View {
        Button {
            onFold(false)
        } label: {
            CardHeader(title, systemImage: "sparkles") {
                Image(systemName: "chevron.down")
                    .textFont(.footnote, weight: .semibold)
                    .foregroundStyle(Palette.subtext)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .card()
    }

    var failed: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今回はひとことを書けませんでした")
                .textFont(.subheadline)
                .foregroundStyle(Palette.subtext)

            footer(isWritten: false)
        }
    }

    func footer(isWritten: Bool) -> some View {
        HStack {
            if isWritten {
                Text("端末の中で書きました")
                    .textFont(.caption)
                    .foregroundStyle(Palette.hint)
            }

            Spacer()

            Button(action: onRewrite) {
                Label("作り直す", systemImage: "arrow.clockwise")
                    .textFont(.caption, weight: .semibold)
                    .foregroundStyle(Palette.accent)
                    .frame(minHeight: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }

    func header(note: String?) -> some View {
        CardHeader(
            title,
            systemImage: "sparkles",
            note: note,
            onClose: {
                onFold(true)
            }
        )
    }

    func ready(_ comment: ReviewComment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(highlighted(comment))
                .textFont(.subheadline)
                .foregroundStyle(Palette.text)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "lightbulb")
                    .foregroundStyle(Palette.accent)

                Text(comment.suggestion)
                    .textFont(.footnote)
                    .foregroundStyle(Palette.accentStrong)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.faint, in: .rect(cornerRadius: 12))

            footer(isWritten: true)
        }
    }

    func needsRecords(_ count: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("記録が \(ReviewComment.minimumEntries) 件たまると、ひとことを書けます")
                .textFont(.subheadline)
                .foregroundStyle(Palette.text)

            HStack(spacing: 4) {
                ForEach(0..<ReviewComment.minimumEntries, id: \.self) { index in
                    Capsule()
                        .fill(index < count ? Palette.accent : Palette.line)
                        .frame(height: 6)
                }
            }

            Text("今は \(count) 件です")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)

            PrimaryButton("記録する", action: onRecord)
        }
    }
}

private extension ReviewCommentCard {
    static let barInsets: [CGFloat] = [0, 40, 120]

    var untilText: String {
        "\(until.yearMonth.month)月\(until.day)日"
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

            text[range].foregroundColor = Palette.rose
        }

        return text
    }
}

#Preview {
    let comment = ReviewComment(
        period: "month:2026-11-01",
        body: "交際費が、前の期間の 8,000円 から 21,000円 に増えています（162% 増）。",
        suggestion: "残りの日は、交際費を少し控えめにすると落ち着きます。",
        basis: "交際費が、前の期間の 8,000円 から 21,000円 に増えています（162% 増）。",
        createdAt: Date()
    )

    let until = LocalDate(year: 2026, month: 11, day: 18) ?? LocalDate(Date(), in: .current)

    VStack(spacing: 12) {
        ReviewCommentCard(
            state: .ready(comment),
            title: "今月のひとこと",
            until: until,
            onRewrite: {},
            onRecord: {},
            onFold: { _ in }
        )

        ReviewCommentCard(
            state: .folded,
            title: "今週のひとこと",
            until: until,
            onRewrite: {},
            onRecord: {},
            onFold: { _ in }
        )
    }
    .padding(16)
}
