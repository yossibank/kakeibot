import Core
import Store
import SwiftUI

public struct StampListView: View {
    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    public var body: some View {
        SettingsBoardPage(StampBoard(database: database))
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let _ = try? database.insertShelfIfEmpty(at: Date())

        NavigationStack {
            StampListView(database: database)
        }
    }
}
