import Core

enum FeatureArtSample {
    struct Item: Hashable {
        let name: String
        let amount: Int
        let rate: EntryItem.TaxRate
    }

    static let store = "スーパー青葉"
    static let date = "2026/11/02 12:30"

    static let items = [
        Item(name: "牛乳", amount: 198, rate: .reduced),
        Item(name: "食パン", amount: 168, rate: .reduced),
        Item(name: "洗剤", amount: 398, rate: .standard)
    ]

    static let budget = 50000
    static let carryover = 8000
    static let remaining = 42180
    static let todayExpense = 1200
    static let weekExpense = 8400
    static let monthExpense = 157_820

    static var total: Int {
        items.reduce(0) {
            $0 + $1.amount
        }
    }
}
