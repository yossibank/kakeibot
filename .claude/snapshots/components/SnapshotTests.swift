import Core
@testable import DesignSystem
@testable import Features
import SwiftUI
import Testing
import UIKit

private let snapshotNow = Date(timeIntervalSince1970: 1_791_774_000)

@MainActor
struct SnapshotTests {
    @Test
    func render() throws {
        let now = snapshotNow
        let today = LocalDate(now, in: .current)
        let september = LocalDate(year: 2026, month: 9, day: 1) ?? today
        let names = ["発表会の衣装と靴", "朝ごはん", "夜ごはん", "まとめ買い", "飲み会", "ランチ会"]
        let tags = names.map { TagLine<String>.Item(id: $0, name: $0) }

        let calendar = MonthCalendar(selection: .constant(september), today: today)
            .padding(16)

        let tagViews = VStack(spacing: 16) {
            TagLine(tags, selection: names.first) { _ in } onAdd: {}

            TagRows(tags, selection: [names[0]]) { _ in }

            HStack(spacing: 8) {
                TagCard(names[0], size: .small)
                TagCard(names[1], style: .selected)
                TagCard("＋", style: .add)
            }
        }
        .padding(16)

        let templates = VStack(spacing: 16) {
            TemplateCard(
                icon: nil,
                name: "子どもの習い事の月謝まとめ払い",
                detail: "子どもの習い事・みずほ銀行",
                amount: 12_345_678,
                size: .large
            )

            HStack(spacing: 12) {
                TemplateCard(
                    icon: nil,
                    name: "子どもの習い事の月謝",
                    detail: "習い事・みずほ銀行",
                    amount: 1_234_567
                )

                TemplateCard(icon: nil, name: "定期", detail: "交通・銀行", amount: nil)
            }
        }
        .padding(16)

        let longMemo = "同僚と駅前の新しいイタリアンでランチ。パスタとサラダのセットに、食後のコーヒーも付けた"
        let longWallet = "みずほ銀行 普通預金 給与と生活費の口座"

        let entryRows = VStack(spacing: 0) {
            EntryRow(
                icon: nil,
                title: "食費",
                detail: "今日・財布",
                memo: "コーヒー",
                amount: 380,
                type: .expense
            )
            EntryRow(
                icon: nil,
                title: "食費",
                detail: "今日・財布",
                memo: longMemo,
                amount: 1200,
                type: .expense
            )
            EntryRow(
                icon: nil,
                title: "食費",
                detail: "11/10・\(longWallet)",
                memo: "スーパー",
                amount: 3300,
                type: .expense
            )
            EntryRow(
                icon: nil,
                title: "食費",
                detail: "11/10・\(longWallet)",
                memo: longMemo,
                amount: 9_876_543,
                type: .expense
            )
            EntryRow(
                icon: nil,
                title: "食費",
                tag: names[0],
                detail: "今日・財布",
                memo: "コーヒー",
                amount: 380,
                type: .expense
            )
            EntryRow(icon: nil, title: "食費", detail: "今日・財布", amount: 380, type: .expense)
        }
        .padding(16)

        for variant in Self.variants {
            try Self.write(entryRows, variant: variant, title: "部品 › 記録の行", to: "parts-entry-rows")
            try Self.write(calendar, variant: variant, title: "部品 › カレンダー", to: "parts-calendar")
            try Self.write(tagViews, variant: variant, title: "部品 › タグ", to: "parts-tags")
            try Self.write(templates, variant: variant, title: "部品 › テンプレート", to: "parts-templates")
        }
    }
}

extension SnapshotTests {
    struct Variant {
        let name: String
        let width: CGFloat
        let scheme: ColorScheme
        let textSize: ThemeTextSize

        var label: String {
            var parts = ["幅 \(Int(width))", scheme == .dark ? "ダーク" : "ライト"]

            switch textSize {
            case .standard: break
            case .small: parts.append("文字小")
            case .large: parts.append("文字大")
            }

            return parts.joined(separator: "・")
        }
    }
}

private extension SnapshotTests {
    static let directory = "__OUT__"
    static let maxHeight: CGFloat = 2400

    static let variants = [
        Variant(name: "regular", width: 393, scheme: .light, textSize: .standard),
        Variant(name: "narrow", width: 320, scheme: .dark, textSize: .large)
    ]

    static func write(
        _ view: some View,
        variant: Variant,
        title: String,
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

        try SnapshotIndex.record(
            directory: directory,
            file: "\(name)-\(variant.name).png",
            title: title,
            variant: variant.label
        )
    }
}
