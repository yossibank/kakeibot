import Core
import Store
import SwiftUI

public struct RewardRuleListView: View {
    private let board: RewardRuleBoard

    public init(database: AppDatabase) {
        self.init(board: RewardRuleBoard(database: database))
    }

    init(board: RewardRuleBoard) {
        self.board = board
    }

    public var body: some View {
        SettingsBoardPage(board)
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        NavigationStack {
            RewardRuleListView(database: database)
        }
    }
}
