@testable import Features
import Testing

@MainActor
struct EntryVoiceInterpreterTests {
    @Test
    func buildsTheSchemaForCategoriesAndWallets() throws {
        guard #available(iOS 26.0, *) else {
            return
        }

        let categories = ["食費", "交通", "食費", ""]
        let wallets = ["財布", "楽天カード"]

        _ = try EntryVoiceInterpreter.schema(categories: categories, wallets: wallets)
    }
}
