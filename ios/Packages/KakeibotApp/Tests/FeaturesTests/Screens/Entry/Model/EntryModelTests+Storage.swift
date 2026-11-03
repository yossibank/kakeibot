import Features
import Testing

extension EntryModelTests {
    @Test
    func tellsWhenIPhoneStorageIsFull() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        model.press(.digit(5))
        model.memo = String(repeating: "あ", count: 100_000)
        try await setup.database.fillStorage()

        let saved = await model.save()

        #expect(saved == nil)
        #expect(model.errorNotice.message == "iPhone の空き容量が足りません")
    }
}
