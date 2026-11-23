import Core
import Store
import SwiftUI

public struct CategoryListView: View {
    private let database: AppDatabase
    private let kind: EntryCategory.Kind

    public init(
        database: AppDatabase,
        kind: EntryCategory.Kind = .expense
    ) {
        self.database = database
        self.kind = kind
    }

    public var body: some View {
        SettingsBoardPage(CategoryBoard(database: database, kind: kind))
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
