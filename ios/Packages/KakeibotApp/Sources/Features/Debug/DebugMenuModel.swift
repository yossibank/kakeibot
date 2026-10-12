#if DEBUG
import Core
import Foundation
import Observation
import Store

@MainActor
@Observable
final class DebugMenuModel {
    private(set) var database: AppDatabase?
    private(set) var sampleEntryId: Entry.ID?
    private(set) var errorMessage: String?
}

extension DebugMenuModel {
    func prepare() async {
        guard database == nil else {
            return
        }

        do {
            let database = try AppDatabase.inMemory()
            let now = Date()
            try database.insertDefaultsIfEmpty(at: now)
            let options = try await database.entryOptions()

            guard let wallet = options.wallets.first,
                  let category = options.expenseCategories.first else {
                return
            }

            let draft = EntryDraft(
                type: .expense,
                amount: 980,
                date: LocalDate(now, in: .current),
                categoryId: category.id,
                walletId: wallet.id,
                memo: "ランチ"
            )

            let entry = try await database.saveEntry(draft, at: now)
            self.database = database
            sampleEntryId = entry.id
        } catch {
            errorMessage = String(describing: error)
        }
    }
}
#endif
