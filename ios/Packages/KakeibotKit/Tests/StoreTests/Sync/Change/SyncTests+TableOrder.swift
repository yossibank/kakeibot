@testable import Store
import Testing

extension SyncTests {
    @Test
    func keepsTablesInParentsFirstOrder() {
        let tables = SyncTable.allCases.map(\.rawValue)

        #expect(tables == Self.parentsFirstTables, Self.tableOrderHint)
    }
}

private extension SyncTests {
    static let tableOrderHint = Comment(
        rawValue: "受け取った行は親の表から書く。順番を変えると外部キーで待たされる行が増える"
    )

    static let parentsFirstTables = [
        "icon",
        "wallet",
        "category",
        "tag",
        "theme",
        "recurring",
        "template",
        "entry",
        "entry_item",
        "item_name",
        "valuation",
        "adjustment",
        "budget",
        "reward_rule",
        "reward_log",
        "reward_goal",
        "calendar_stamp",
        "shelf_icon",
        "no_spend_day",
        "setting"
    ]
}
