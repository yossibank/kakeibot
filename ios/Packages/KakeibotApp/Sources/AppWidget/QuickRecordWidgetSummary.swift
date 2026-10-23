import Core
import DesignSystem
import Foundation
import Store

struct QuickRecordWidgetSummary: Hashable, Sendable {
    let todayExpense: Int
    let tiles: [Tile]
    let todayRecords: [Record]
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
        let amount: Int
        let type: Entry.Kind
    }

    struct Recorded: Hashable, Sendable {
        let id: Entry.ID
        let name: String
        let amount: Int
        let until: Date
    }

    static let limit = 8
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

        let records = (today?.entries ?? []).prefix(Self.recordLimit).map { entry in
            Record(
                id: entry.id,
                title: list?.title(of: entry) ?? "",
                amount: entry.amount,
                type: entry.type
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
            recorded: recorded
        )
    }

    static func sample() -> QuickRecordWidgetSummary {
        let tiles = [
            ("コーヒー", "カフェ・財布", 450),
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
            Record(id: Entry.ID(), title: "食費", amount: 980, type: .expense),
            Record(id: Entry.ID(), title: "カフェ", amount: 140, type: .expense)
        ]

        return QuickRecordWidgetSummary(
            todayExpense: 1120,
            tiles: tiles,
            todayRecords: records,
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
            recorded: nil
        )
    }
}
