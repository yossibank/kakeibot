import Core
import Store
import SwiftUI

public struct RewardRuleListView: View {
    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    public var body: some View {
        SettingsBoardPage(RewardRuleBoard(database: database))
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        NavigationStack {
            RewardRuleListView(database: database)
        }
    }
}
