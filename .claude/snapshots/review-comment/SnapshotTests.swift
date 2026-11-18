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

        let rows = [
            ReviewBreakdown.Row(name: "いなげや", count: 6, previousCount: 6, amount: 21300),
            ReviewBreakdown.Row(name: "セブン", count: 12, previousCount: 8, amount: 8400),
            ReviewBreakdown.Row(name: "パン屋 こむぎ", count: 3, previousCount: 5, amount: 2900)
        ]

        let summary = ReviewBreakdown.Summary(
            focus: ReviewBreakdown.Focus(
                name: "食費",
                count: 28,
                previousCount: 20,
                amount: 39200,
                previousAmount: 28000
            ),
            rows: rows,
            goodPoint: "外食は、前の月の 6 回から 3 回に減っています。",
            action: ReviewBreakdown.Action(lead: "食費を前の月と同じ 20 回ほどに戻すと", amount: 11200)
        )

        let breakdown = ReviewComment(
            period: "month:2026-11-01",
            body: "食費が増えたのは、回数が 8 回増えたためです。1 回の額は前の月と変わりません。",
            suggestion: summary.action?.sentence ?? "",
            basis: basis,
            createdAt: Date(),
            breakdown: summary
        )

        let states: [(String, ReviewModel.CommentState)] = [
            ("ready", .ready(comment)),
            ("breakdown", .ready(breakdown)),
            ("loading", .loading),
            ("records", .needsRecords(2)),
            ("failed", .failed)
        ]

        for variant in Self.variants {
            for (name, state) in states {
                let view = VStack(spacing: 12) {
                    ReviewDisplaySwitch(display: .chart, state: state, onSelect: { _ in })

                    ReviewAnalysisView(
                        state: state,
                        note: "11/1–11/18 · 42 件",
                        unit: "月",
                        currentName: "今月",
                        onRewrite: {},
                        onRecord: {}
                    )
                }
                .padding(16)

                try Self.write(view, variant: variant, to: "review-comment-\(name)")
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
        Variant(name: "light", width: 393, scheme: .light, textSize: .standard),
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

        let preset: ThemePreset = variant.scheme == .dark ? .black : .white

        let content = view
            .frame(width: variant.width)
            .frame(maxHeight: maxHeight, alignment: .top)
            .clipped()
            .background(Palette.background)
            .environment(\.themeStyle, style)
            .environment(\.palette, preset.palette)
            .environment(\.colorScheme, variant.scheme)

        let renderer = ImageRenderer(content: content)

        renderer.scale = 2
        renderer.proposedSize = ProposedViewSize(width: variant.width, height: nil)

        let data = try #require(renderer.uiImage?.pngData())
        let url = URL(fileURLWithPath: directory).appending(path: "\(name)-\(variant.name).png")

        try data.write(to: url)
    }
}
