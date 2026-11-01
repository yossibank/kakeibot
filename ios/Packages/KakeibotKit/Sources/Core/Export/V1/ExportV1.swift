import Foundation

public struct ExportV1: Hashable, Sendable {
    public var exportedAt: Date
    public var app: App
    public var data: Tables

    public init(
        exportedAt: Date,
        app: App,
        data: Tables
    ) {
        self.exportedAt = exportedAt
        self.app = app
        self.data = data
    }

    public init(json: Data) throws {
        let decoder = JSONDecoder()

        decoder.dateDecodingStrategy = .iso8601
        self = try decoder.decode(Self.self, from: json)
    }
}

public extension ExportV1 {
    enum ReadError: Error, Equatable {
        case unknownFormat(String)
        case unsupportedVersion(Int)
        case missingTransfer
    }

    enum Platform: String, CaseIterable, Codable, Sendable {
        case ios
        case android
    }

    struct App: Codable, Hashable, Sendable {
        public var platform: Platform
        public var version: String

        public init(
            platform: Platform,
            version: String
        ) {
            self.platform = platform
            self.version = version
        }
    }

    struct Tables: Hashable, Sendable {
        public var icons: [Icon]
        public var shelfIcons: [ShelfIcon]
        public var wallets: [Wallet]
        public var valuations: [Valuation]
        public var categories: [EntryCategory]
        public var tags: [EntryTag]
        public var entries: [Entry]
        public var entryItems: [EntryItem]
        public var itemNames: [ItemName]
        public var templates: [EntryTemplate]
        public var budgets: [Budget]
        public var recurrings: [Recurring]
        public var rewardRules: [RewardRule]
        public var rewardLogs: [RewardLog]
        public var rewardGoals: [RewardGoal]
        public var calendarStamps: [CalendarStamp]
        public var noSpendDays: [NoSpendDay]
        public var themes: [Theme]
        public var settings: [Setting]

        public init(
            icons: [Icon],
            shelfIcons: [ShelfIcon] = [],
            wallets: [Wallet],
            valuations: [Valuation] = [],
            categories: [EntryCategory],
            tags: [EntryTag] = [],
            entries: [Entry],
            entryItems: [EntryItem] = [],
            itemNames: [ItemName] = [],
            templates: [EntryTemplate] = [],
            budgets: [Budget],
            recurrings: [Recurring],
            rewardRules: [RewardRule],
            rewardLogs: [RewardLog],
            rewardGoals: [RewardGoal],
            calendarStamps: [CalendarStamp],
            noSpendDays: [NoSpendDay],
            themes: [Theme],
            settings: [Setting]
        ) {
            self.icons = icons
            self.shelfIcons = shelfIcons
            self.wallets = wallets
            self.valuations = valuations
            self.categories = categories
            self.tags = tags
            self.entries = entries
            self.entryItems = entryItems
            self.itemNames = itemNames
            self.templates = templates
            self.budgets = budgets
            self.recurrings = recurrings
            self.rewardRules = rewardRules
            self.rewardLogs = rewardLogs
            self.rewardGoals = rewardGoals
            self.calendarStamps = calendarStamps
            self.noSpendDays = noSpendDays
            self.themes = themes
            self.settings = settings
        }
    }

    static let format = "kakeibot-export"
    static let version = 1

    func json() throws -> Data {
        let encoder = JSONEncoder()

        encoder.dateEncodingStrategy = .iso8601

        encoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys,
            .withoutEscapingSlashes
        ]

        return try encoder.encode(self)
    }
}

private extension ExportV1 {
    enum CodingKeys: String, CodingKey {
        case format
        case version
        case exportedAt
        case app
        case data
    }
}

extension ExportV1: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let format = try container.decode(String.self, forKey: .format)
        let version = try container.decode(Int.self, forKey: .version)

        guard format == Self.format else {
            throw ReadError.unknownFormat(format)
        }

        guard version == Self.version else {
            throw ReadError.unsupportedVersion(version)
        }

        let exportedAt = try container.decode(Date.self, forKey: .exportedAt)
        let app = try container.decode(App.self, forKey: .app)
        let data = try container.decode(Tables.self, forKey: .data)

        guard data.hasTransferForEveryFee else {
            throw ReadError.missingTransfer
        }

        self.init(exportedAt: exportedAt, app: app, data: data)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(Self.format, forKey: .format)
        try container.encode(Self.version, forKey: .version)
        try container.encode(exportedAt, forKey: .exportedAt)
        try container.encode(app, forKey: .app)
        try container.encode(data, forKey: .data)
    }
}

private extension ExportV1.Tables {
    var hasTransferForEveryFee: Bool {
        let transferIds = entries.filter { $0.type == .transfer }.map(\.id)
        let transfers = Set(transferIds)
        return entries.compactMap(\.transferId).allSatisfy(transfers.contains)
    }
}

extension ExportV1.Tables: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let icons = try container.decode([Icon].self, forKey: .icons)
        let shelfIcons = try container.decodeIfPresent([ShelfIcon].self, forKey: .shelfIcons)
        let wallets = try container.decode([Wallet].self, forKey: .wallets)
        let valuations = try container.decodeIfPresent([Valuation].self, forKey: .valuations)
        let categories = try container.decode([EntryCategory].self, forKey: .categories)
        let tags = try container.decodeIfPresent([EntryTag].self, forKey: .tags)
        let entries = try container.decode([Entry].self, forKey: .entries)
        let entryItems = try container.decodeIfPresent([EntryItem].self, forKey: .entryItems)
        let itemNames = try container.decodeIfPresent([ItemName].self, forKey: .itemNames)
        let templates = try container.decodeIfPresent([EntryTemplate].self, forKey: .templates)
        let budgets = try container.decode([Budget].self, forKey: .budgets)
        let recurrings = try container.decode([Recurring].self, forKey: .recurrings)
        let rewardRules = try container.decode([RewardRule].self, forKey: .rewardRules)
        let rewardLogs = try container.decode([RewardLog].self, forKey: .rewardLogs)
        let rewardGoals = try container.decode([RewardGoal].self, forKey: .rewardGoals)
        let calendarStamps = try container.decode([CalendarStamp].self, forKey: .calendarStamps)
        let noSpendDays = try container.decode([NoSpendDay].self, forKey: .noSpendDays)
        let themes = try container.decode([Theme].self, forKey: .themes)
        let settingRows = try container.decode([SettingRow].self, forKey: .settings)
        let settings = settingRows.compactMap(\.setting)

        self.init(
            icons: icons,
            shelfIcons: shelfIcons ?? [],
            wallets: wallets,
            valuations: valuations ?? [],
            categories: categories,
            tags: tags ?? [],
            entries: entries,
            entryItems: entryItems ?? [],
            itemNames: itemNames ?? [],
            templates: templates ?? [],
            budgets: budgets,
            recurrings: recurrings,
            rewardRules: rewardRules,
            rewardLogs: rewardLogs,
            rewardGoals: rewardGoals,
            calendarStamps: calendarStamps,
            noSpendDays: noSpendDays,
            themes: themes,
            settings: settings
        )
    }
}

private struct SettingRow: Decodable {
    let key: String
    let value: String
}

extension SettingRow {
    var setting: Setting? {
        Setting.Key(rawValue: key).map { Setting(key: $0, value: value) }
    }
}
