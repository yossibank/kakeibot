import Core
import Store
import SwiftUI

public struct CategoryListView: View {
    private let board: CategoryBoard

    public init(
        database: AppDatabase,
        kind: EntryCategory.Kind = .expense
    ) {
        self.init(board: CategoryBoard(database: database, kind: kind))
    }

    init(board: CategoryBoard) {
        self.board = board
    }

    public var body: some View {
        SettingsBoardPage(board)
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())

        NavigationStack {
            CategoryListView(database: database)
        }
    }
}
