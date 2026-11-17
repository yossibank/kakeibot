import Core
@testable import DesignSystem
@testable import Features
import SwiftUI
import Testing
import UIKit

@MainActor
struct SnapshotTests {
    @Test
    func render() throws {
        let basis = "気を付けたい点：食費は、月の 60% が過ぎたところで、予算の 97% を使っています。\n気を付けたい点：交際費が、前の月の 8,000円 から 21,000円 に増えています（162% 増）。"

        let comment = ReviewComment(
            period: "month:2026-11-01",
            body: "食費が、月の 60% で予算の 97% に届いています。交際費も 162% 増えています。",
            suggestion: "食費は、残りの 12 日を 1 日 150円 にすると、予算に収まります。",
            basis: basis,
            createdAt: Date()
        )

        let states: [(String, ReviewModel.CommentState)] = [
            ("ready", .ready(comment)),
            ("loading", .loading),
            ("records", .needsRecords(2)),
            ("folded", .folded),
            ("failed", .failed)
        ]

        for variant in Self.variants {
            for (name, state) in states {
                let card = ReviewCommentCard(
                    state: state,
                    title: "今月のひとこと",
                    until: LocalDate(year: 2026, month: 11, day: 18) ?? LocalDate(
                        Date(),
                        in: .current
                    ),
                    onRewrite: {},
                    onRecord: {},
                    onFold: { _ in }
                )
                .padding(16)

                try Self.write(card, variant: variant, to: "review-comment-\(name)")
            }
        }
    }
}

extension SnapshotTests {
    struct Variant {
        let name: String
        let width: CGFloat
        let scheme: ColorScheme
        let textSize: ThemeTextSize
    }
}

private extension SnapshotTests {
    static let directory = "__OUT__"
    static let maxHeight: CGFloat = 2400

    static let variants = [
        Variant(name: "regular", width: 393, scheme: .dark, textSize: .standard),
        Variant(name: "narrow", width: 320, scheme: .light, textSize: .large)
    ]

    static func write(
        _ view: some View,
        variant: Variant,
        to name: String
    ) throws {
        let style = ThemeStyle(
            corner: .standard,
            displayFont: .mincho,
            textFont: .gothic,
            textSize: variant.textSize
        )

        let content = view
            .frame(width: variant.width)
            .frame(maxHeight: maxHeight, alignment: .top)
            .clipped()
            .background(Palette.background)
            .environment(\.themeStyle, style)
            .environment(\.colorScheme, variant.scheme)

        let renderer = ImageRenderer(content: content)

        renderer.scale = 2
        renderer.proposedSize = ProposedViewSize(width: variant.width, height: nil)

        let data = try #require(renderer.uiImage?.pngData())
        let url = URL(fileURLWithPath: directory).appending(path: "\(name)-\(variant.name).png")

        try data.write(to: url)
    }
}
