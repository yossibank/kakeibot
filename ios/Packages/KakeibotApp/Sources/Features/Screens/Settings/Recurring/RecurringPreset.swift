import Core

public struct RecurringPreset: Hashable, Sendable {
    public let title: String
    public let systemImage: String
    public let categoryNames: [String]
    public let glyphs: [Icon.Glyph]
    public let month: Int?
    public let day: Int
    public let holidayShift: HolidayShift
    public let destination: Wallet.Kind?
}

extension RecurringPreset {
    static func presets(for type: Entry.Kind) -> [RecurringPreset] {
        switch type {
        case .expense: [rent, subscription, utility, phone]
        case .income: [salary, bonus]
        case .transfer: [cardBill, saving]
        }
    }
}

private extension RecurringPreset {
    static let rent = RecurringPreset(
        title: "家賃",
        systemImage: "house",
        categoryNames: ["家賃", "住居", "住居費"],
        glyphs: [.home],
        month: nil,
        day: 27,
        holidayShift: .previous,
        destination: nil
    )

    static let subscription = RecurringPreset(
        title: "サブスク",
        systemImage: "play.rectangle",
        categoryNames: ["サブスク", "娯楽", "趣味"],
        glyphs: [.music, .movie, .tv],
        month: nil,
        day: 1,
        holidayShift: .none,
        destination: nil
    )

    static let utility = RecurringPreset(
        title: "光熱費",
        systemImage: "bolt",
        categoryNames: ["光熱費", "水道・光熱費", "水道光熱費"],
        glyphs: [.utility, .light],
        month: nil,
        day: 26,
        holidayShift: .next,
        destination: nil
    )

    static let phone = RecurringPreset(
        title: "通信",
        systemImage: "iphone",
        categoryNames: ["通信", "通信費"],
        glyphs: [.phone, .wifi],
        month: nil,
        day: 27,
        holidayShift: .next,
        destination: nil
    )

    static let salary = RecurringPreset(
        title: "給料",
        systemImage: "yensign",
        categoryNames: ["給料", "給与"],
        glyphs: [.salary],
        month: nil,
        day: 25,
        holidayShift: .previous,
        destination: nil
    )

    static let bonus = RecurringPreset(
        title: "ボーナス",
        systemImage: "gift",
        categoryNames: ["ボーナス", "賞与"],
        glyphs: [.bonus],
        month: 12,
        day: 10,
        holidayShift: .previous,
        destination: nil
    )

    static let cardBill = RecurringPreset(
        title: "カード",
        systemImage: "creditcard",
        categoryNames: [],
        glyphs: [],
        month: nil,
        day: 27,
        holidayShift: .next,
        destination: .card
    )

    static let saving = RecurringPreset(
        title: "積立",
        systemImage: "chart.line.uptrend.xyaxis",
        categoryNames: [],
        glyphs: [],
        month: nil,
        day: 27,
        holidayShift: .next,
        destination: .investment
    )
}
