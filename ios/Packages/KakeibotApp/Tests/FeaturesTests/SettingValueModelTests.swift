import Core
import Features
import Store
import Testing

@MainActor
struct SettingValueModelTests {
    @Test
    func startsWithAmountUntilTurnedOff() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = SettingValueModel(database: setup.database, key: .entryStartsWithAmount)
        await model.load()
        let before = model.value

        await model.choose(false)
        let saved = try await setup.database.setting(.entryStartsWithAmount)

        #expect(before)
        #expect(!model.value)
        #expect(!saved)
    }

    @Test
    func savesChosenDay() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = SettingValueModel(database: setup.database, key: .weekStart)
        await model.load()

        await model.choose(.monday)
        let saved = try await setup.database.setting(.weekStart)

        #expect(model.value == .monday)
        #expect(saved == .monday)
        #expect(model.errorNotice.message == nil)
    }

    @Test
    func rollsBackAndTellsWhenSavingFails() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = SettingValueModel(database: setup.database, key: .weekStart)
        await model.load()
        try await setup.database.failWrites(to: "setting")

        await model.choose(.monday)
        let saved = try await setup.database.setting(.weekStart)

        #expect(model.value == .sunday)
        #expect(saved == .sunday)
        #expect(model.errorNotice.message == "設定を保存できませんでした")
    }

    @Test
    func keepsLaterChoiceWhenEarlierSaveFails() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = SettingValueModel(database: setup.database, key: .weekStart)
        await model.load()

        try await setup.database.writer.write { db in
            for event in ["INSERT", "UPDATE"] {
                try db.execute(
                    sql: """
                    CREATE TRIGGER fail_monday_\(event.lowercased()) BEFORE \(event) ON setting
                    WHEN instr(NEW.value, 'monday') > 0
                    BEGIN SELECT RAISE(ABORT, 'failing for tests'); END
                    """
                )
            }
        }

        let first = Task {
            await model.choose(.monday)
        }

        let second = Task {
            await model.choose(.tuesday)
        }

        await first.value
        await second.value
        let saved = try await setup.database.setting(.weekStart)

        #expect(model.value == .tuesday)
        #expect(saved == .tuesday)
    }

    @Test
    func returnsToSavedDayWhenBothQuickSavesFail() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = SettingValueModel(database: setup.database, key: .weekStart)
        await model.load()
        try await setup.database.failWrites(to: "setting")

        let first = Task {
            await model.choose(.monday)
        }

        let second = Task {
            await model.choose(.tuesday)
        }

        await first.value
        await second.value
        let saved = try await setup.database.setting(.weekStart)

        #expect(model.value == .sunday)
        #expect(saved == .sunday)
    }
}
