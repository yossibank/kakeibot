import Core
import DesignSystem
import Foundation
import Store

struct QuickRecordWidgetSummary: Hashable, Sendable {
    let todayExpense: Int
    let tiles: [Tile]
    let todayRecords: [Record]
    let todayCount: Int
    let recorded: Recorded?
}

extension QuickRecordWidgetSummary {
    struct Tile: Hashable, Identifiable, Sendable {
        let id: EntryTemplate.ID
        let name: String
        let detail: String
        let amount: Int?
        let icon: Icon?
    }

    struct Record: Hashable, Identifiable, Sendable {
        let id: Entry.ID
        let title: String
        let detail: String
        let amount: Int
        let type: Entry.Kind
        let icon: Icon?
    }

    struct Recorded: Hashable, Sendable {
        let id: Entry.ID
        let name: String
        let amount: Int
        let until: Date
    }

    static let limit = 6
    static let recordLimit = 2
    static let undoInterval: TimeInterval = 60

    init(
        _ overview: MonthOverview,
        templates: [EntryTemplate],
        order: TemplateOrder,
        recordedId: Entry.ID?
    ) {
        let list = overview.list
        let expenses = templates.filter { $0.type == .expense }
        let ordered = list?.ordered(expenses, by: order, today: overview.today) ?? expenses
        let today = list?.days.first { $0.date == overview.today }

        let tiles = ordered.prefix(Self.limit).map { template in
            Tile(
                id: template.id,
                name: template.name,
                detail: list?.detailParts(for: template).rowDetail ?? "",
                amount: template.amount,
                icon: list?.icon(for: template)
            )
        }

        let todayEntries = today?.entries ?? []

        let records = todayEntries.prefix(Self.recordLimit).map { entry in
            let template = templates.first { $0.id == entry.templateId }
            let memo = entry.memo.flatMap { $0.isEmpty ? nil : $0 }
            let wallet = list?.wallets[entry.walletId]?.name
            let category = entry.categoryId.flatMap { list?.categories[$0] }

            return Record(
                id: entry.id,
                title: list?.title(of: entry) ?? "",
                detail: [template?.name ?? memo, wallet].rowDetail ?? "",
                amount: entry.amount,
                type: entry.type,
                icon: category.flatMap { list?.icons[$0.iconId] }
            )
        }

        let entry = recordedId.flatMap { id in
            list?.days
                .lazy
                .flatMap(\.entries)
                .first { $0.id == id }
        }

        let recorded = entry.map { entry in
            let template = templates.first { $0.id == entry.templateId }

            return Recorded(
                id: entry.id,
                name: template?.name ?? list?.title(of: entry) ?? "記録",
                amount: entry.amount,
                until: entry.createdAt.addingTimeInterval(Self.undoInterval)
            )
        }

        self.init(
            todayExpense: overview.todayExpense,
            tiles: Array(tiles),
            todayRecords: Array(records),
            todayCount: todayEntries.count,
            recorded: recorded
        )
    }

    static func sample() -> QuickRecordWidgetSummary {
        let tiles = [
            ("駅前のカフェでモーニング", "カフェ・財布", 650),
            ("ランチ", "食費・財布", 980),
            ("電車", "交通・カード", 220),
            ("外食", "食費・カード", nil),
            ("本", "趣味・カード", 1500),
            ("ジム", "健康・銀行", 800),
            ("おやつ", "食費・財布", 300),
            ("日用品", "日用品・カード", 1200)
        ].map { name, detail, amount in
            Tile(
                id: EntryTemplate.ID(),
                name: name,
                detail: detail,
                amount: amount,
                icon: nil
            )
        }

        let records = [
            Record(
                id: Entry.ID(),
                title: "食費",
                detail: "ランチ・財布",
                amount: 980,
                type: .expense,
                icon: nil
            ),
            Record(
                id: Entry.ID(),
                title: "カフェ",
                detail: "コーヒー・カード",
                amount: 140,
                type: .expense,
                icon: nil
            )
        ]

        return QuickRecordWidgetSummary(
            todayExpense: 1120,
            tiles: tiles,
            todayRecords: records,
            todayCount: 3,
            recorded: nil
        )
    }

    func recorded(at date: Date) -> Recorded? {
        recorded.flatMap { $0.until > date ? $0 : nil }
    }

    func clearingRecorded() -> QuickRecordWidgetSummary {
        QuickRecordWidgetSummary(
            todayExpense: todayExpense,
            tiles: tiles,
            todayRecords: todayRecords,
            todayCount: todayCount,
            recorded: nil
        )
    }
}
