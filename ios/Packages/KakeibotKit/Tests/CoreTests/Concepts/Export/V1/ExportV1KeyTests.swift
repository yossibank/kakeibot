import Core
import Foundation
import Testing

struct ExportV1KeyTests {
    private static let hint = Comment(
        rawValue: "Core の型のプロパティの名前を変えたら、CodingKeys でキーを元のままに保つ"
    )

    @Test
    func encodesKeysOfFixture() throws {
        let expected = try Self.keyPaths(CoreFixture.data("export/export-v1.json"))

        let encoded = try Self.keyPaths(Self.sample.json())

        #expect(encoded.subtracting(expected).sorted() == [], Self.hint)
        #expect(expected.subtracting(encoded).sorted() == [], Self.hint)
    }

    @Test
    func keepsKeysOfFixtureThroughRoundTrip() throws {
        let fixture = try CoreFixture.data("export/export-v1.json")
        let expected = try Self.keyPaths(fixture)

        let written = try Self.keyPaths(ExportV1(json: fixture).json())

        #expect(written.subtracting(expected).sorted() == [], Self.hint)
        #expect(expected.subtracting(written).sorted() == [], Self.hint)
    }

    @Test
    func listsTablesOfSpec() throws {
        let fixture = try Self.keyPaths(CoreFixture.data("export/export-v1.json"))
        let expected = fixture.filter { !$0.contains("[]") }

        let spec = try Self.keyPaths(Self.specExample())

        #expect(spec.subtracting(expected).sorted() == [], "export-format.md の JSON の例を見本に合わせる")
        #expect(expected.subtracting(spec).sorted() == [], "export-format.md の JSON の例を見本に合わせる")
    }
}

private extension ExportV1KeyTests {
    static let now = Date(timeIntervalSince1970: 1_791_000_000)
    static let day = LocalDate("2026-02-27")!
    static let month = YearMonth("2026-01")!

    static let sample = ExportV1(
        exportedAt: now,
        app: ExportV1.App(platform: .ios, version: "1.0.0"),
        data: ExportV1.Tables(
            icons: [
                Icon(
                    emoji: "🍙",
                    text: "ご",
                    glyph: .food,
                    color: "#FF8800",
                    createdAt: now,
                    updatedAt: now
                )
            ],
            shelfIcons: [
                ShelfIcon(
                    iconId: Icon.ID(),
                    sortOrder: 1,
                    archivedAt: now,
                    createdAt: now,
                    updatedAt: now
                )
            ],
            wallets: [
                Wallet(
                    name: "奨学金",
                    kind: .loan,
                    iconId: Icon.ID(),
                    initialBalance: -240_000,
                    loanAmount: 300_000,
                    sortOrder: 2,
                    archivedAt: now,
                    createdAt: now,
                    updatedAt: now
                )
            ],
            valuations: [
                Valuation(
                    walletId: Wallet.ID(),
                    date: day,
                    amount: 1000,
                    createdAt: now,
                    updatedAt: now
                )
            ],
            adjustments: [
                Adjustment(
                    walletId: Wallet.ID(),
                    date: day,
                    amount: -300,
                    createdAt: now,
                    updatedAt: now
                )
            ],
            categories: [
                EntryCategory(
                    kind: .expense,
                    name: "食費",
                    iconId: Icon.ID(),
                    sortOrder: 0,
                    archivedAt: now,
                    walletId: Wallet.ID(),
                    createdAt: now,
                    updatedAt: now
                )
            ],
            tags: [
                EntryTag(
                    categoryId: EntryCategory.ID(),
                    name: "外食",
                    sortOrder: 0,
                    archivedAt: now,
                    createdAt: now,
                    updatedAt: now
                )
            ],
            entries: [
                Entry(
                    type: .expense,
                    amount: 980,
                    date: day,
                    categoryId: EntryCategory.ID(),
                    tagId: EntryTag.ID(),
                    templateId: EntryTemplate.ID(),
                    walletId: Wallet.ID(),
                    toWalletId: Wallet.ID(),
                    memo: "動画",
                    recurringId: Recurring.ID(),
                    recurringDate: day,
                    billMonth: month,
                    transferId: Entry.ID(),
                    taxIncluded: true,
                    createdAt: now,
                    updatedAt: now
                )
            ],
            entryItems: [
                EntryItem(
                    entryId: Entry.ID(),
                    name: "おにぎり",
                    quantity: 2,
                    amount: 300,
                    taxRate: .reduced,
                    sortOrder: 0,
                    createdAt: now,
                    updatedAt: now
                )
            ],
            itemNames: [
                ItemName(store: "コンビニ", raw: "ｵﾆｷﾞﾘ", name: "おにぎり", createdAt: now, updatedAt: now)
            ],
            templates: [
                EntryTemplate(
                    name: "昼ごはん",
                    type: .expense,
                    amount: 800,
                    categoryId: EntryCategory.ID(),
                    tagId: EntryTag.ID(),
                    walletId: Wallet.ID(),
                    memo: "社食",
                    billShift: 1,
                    sortOrder: 0,
                    archivedAt: now,
                    createdAt: now,
                    updatedAt: now
                )
            ],
            budgets: [
                Budget(categoryId: EntryCategory.ID(), fromMonth: month, amount: 30000)
            ],
            recurrings: [
                Recurring(
                    type: .transfer,
                    amount: 980,
                    categoryId: EntryCategory.ID(),
                    walletId: Wallet.ID(),
                    toWalletId: Wallet.ID(),
                    memo: "カード",
                    frequency: .yearly,
                    month: 3,
                    day: 27,
                    holidayShift: .next,
                    closingDay: 15,
                    fee: 110,
                    finalAmount: 500,
                    billShift: 1,
                    startDate: day,
                    endDate: day,
                    remindDaysBefore: 2,
                    generatedUntil: day,
                    sortOrder: 1,
                    archivedAt: now,
                    createdAt: now,
                    updatedAt: now
                )
            ],
            rewardRules: [
                RewardRule(
                    name: "自炊した日",
                    amount: 300,
                    iconId: Icon.ID(),
                    isActive: true,
                    sortOrder: 0,
                    createdAt: now,
                    updatedAt: now
                )
            ],
            rewardLogs: [
                RewardLog(ruleId: RewardRule.ID(), date: day, amount: 300, createdAt: now)
            ],
            rewardGoals: [
                RewardGoal(
                    name: "新しい靴",
                    targetAmount: 8000,
                    purchasedAt: now,
                    entryId: Entry.ID(),
                    createdAt: now,
                    updatedAt: now
                )
            ],
            calendarStamps: [
                CalendarStamp(date: day, iconId: Icon.ID(), createdAt: now)
            ],
            noSpendDays: [
                NoSpendDay(date: day, createdAt: now)
            ],
            themes: [
                Theme(
                    name: "標準",
                    background: "#FFFFFF",
                    surface: "#F5F5F5",
                    textPrimary: "#111111",
                    textSecondary: "#666666",
                    accent: "#FF8800",
                    expense: "#D33F49",
                    income: "#2E8B57",
                    cornerRadius: 12,
                    fontId: "system",
                    isBuiltin: true,
                    createdAt: now,
                    updatedAt: now
                )
            ],
            settings: [
                Setting(key: .monthStartDay, value: "25")
            ]
        )
    )

    static func keyPaths(_ data: Data) throws -> Set<String> {
        let object = try JSONSerialization.jsonObject(with: data)
        var paths: Set<String> = []

        collect(object, path: "", into: &paths)

        return paths
    }

    static func collect(_ value: Any, path: String, into paths: inout Set<String>) {
        if let object = value as? [String: Any] {
            for (key, child) in object {
                let childPath = path.isEmpty ? key : "\(path).\(key)"

                paths.insert(childPath)
                collect(child, path: childPath, into: &paths)
            }
        } else if let array = value as? [Any] {
            for child in array {
                collect(child, path: "\(path)[]", into: &paths)
            }
        }
    }

    static func specExample() throws -> Data {
        let markdown = try String(decoding: CoreFixture.spec("export-format.md"), as: UTF8.self)
        let start = try #require(markdown.range(of: "```json\n"))
        let end = try #require(markdown.range(
            of: "\n```",
            range: start.upperBound..<markdown.endIndex
        ))

        return Data(markdown[start.upperBound..<end.lowerBound].utf8)
    }
}
