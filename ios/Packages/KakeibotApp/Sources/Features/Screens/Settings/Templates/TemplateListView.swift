import Core
import Store
import SwiftUI

public struct TemplateListView: View {
    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    public var body: some View {
        SettingsBoardPage(TemplateBoard(database: database))
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())

        NavigationStack {
            TemplateListView(database: database)
        }
    }
}
