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
}

public extension ExportV1 {
    enum ReadError: Error, Equatable {
        case unknownFormat(String)
        case unsupportedVersion(Int)
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

    struct Tables: Codable, Hashable, Sendable {
        public var icons: [Icon]
        public var wallets: [Wallet]
        public var categories: [EntryCategory]
        public var entries: [Entry]
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
            wallets: [Wallet],
            categories: [EntryCategory],
            entries: [Entry],
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
            self.wallets = wallets
            self.categories = categories
            self.entries = entries
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

    init(json: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self = try decoder.decode(Self.self, from: json)
    }

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

        self.init(
            exportedAt: exportedAt,
            app: app,
            data: data
        )
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
