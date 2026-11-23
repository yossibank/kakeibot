import Core
import Store
import SwiftUI

public struct WalletListView: View {
    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    public var body: some View {
        SettingsBoardPage(WalletBoard(database: database))
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())

        NavigationStack {
            WalletListView(database: database)
        }
    }
}
