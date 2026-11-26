import FeatureModels
import Features
import Testing

extension EntryModelTests {
    @Test
    func tellsWhenIPhoneStorageIsFull() async throws {
        let setup = try await Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()
        model.state.press(.digit(5))
        model.state.fields.memo = String(repeating: "あ", count: 100_000)
        try await setup.database.fillStorage()

        let saved = await model.save()

        #expect(saved == nil)
        #expect(model.state.errorNotice.message == "\(DeviceName.current) の空き容量が足りません")
    }
}
