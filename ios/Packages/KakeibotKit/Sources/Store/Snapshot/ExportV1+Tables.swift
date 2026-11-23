import Core
import GRDB

extension ExportV1.Tables {
    init(fetchingFrom db: Database) throws {
        var tables = Self.empty

        for column in Self.columns {
            try column.read(db, &tables)
        }

        self = tables
    }

    static func deleteAll(in db: Database) throws {
        for column in columns.reversed() {
            try column.type.deleteAll(db)
        }
    }

    func insert(into db: Database) throws {
        for column in Self.columns {
            for record in column.records(self) {
                try record.insert(db)
            }
        }
    }
}

private extension ExportV1.Tables {
    static var empty: Self {
        Self(
            icons: [],
            wallets: [],
            categories: [],
            entries: [],
            budgets: [],
            recurrings: [],
            rewardRules: [],
            rewardLogs: [],
            rewardGoals: [],
            calendarStamps: [],
            noSpendDays: [],
            themes: [],
            settings: []
        )
    }

    static var columns: [TableColumn] {
        let exportedSettings = Setting.filter(Setting.Key.exported.contains(Column("key")))

        return [
            TableColumn(\.icons),
            TableColumn(\.shelfIcons),
            TableColumn(\.wallets),
            TableColumn(\.valuations),
            TableColumn(\.adjustments),
            TableColumn(\.categories),
            TableColumn(\.tags),
            TableColumn(\.recurrings),
            TableColumn(\.templates),
            TableColumn(\.entries, insertOrder: transfersBeforeFees),
            TableColumn(\.entryItems),
            TableColumn(\.itemNames),
            TableColumn(\.budgets),
            TableColumn(\.rewardRules),
            TableColumn(\.rewardLogs),
            TableColumn(\.rewardGoals),
            TableColumn(\.calendarStamps),
            TableColumn(\.noSpendDays),
            TableColumn(\.themes),
            TableColumn(\.settings, request: exportedSettings)
        ]
    }

    static func transfersBeforeFees(_ entries: [Entry]) -> [Entry] {
        entries.filter { $0.transferId == nil } + entries.filter { $0.transferId != nil }
    }
}

private struct TableColumn {
    let type: any StoreRecord.Type
    let read: (Database, inout ExportV1.Tables) throws -> Void
    let records: (ExportV1.Tables) -> [any StoreRecord]
}

private extension TableColumn {
    init<Record: StoreRecord>(
        _ keyPath: WritableKeyPath<ExportV1.Tables, [Record]>,
        request: QueryInterfaceRequest<Record> = Record.all(),
        insertOrder: @escaping ([Record]) -> [Record] = { $0 }
    ) {
        self.type = Record.self

        self.read = { db, tables in
            tables[keyPath: keyPath] = try request.orderByPrimaryKey().fetchAll(db)
        }

        self.records = { tables in
            insertOrder(tables[keyPath: keyPath])
        }
    }
}
