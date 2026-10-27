import Core
@testable import Store
import Testing

struct MigrationFrozenValuesTests {
    private static let hint = Comment(
        rawValue: "enum に case を足したら、表を作り直すマイグレーションを足す"
    )

    @Test
    func walletKindsMatchCurrentCases() {
        let current = Set(Wallet.Kind.allCases.map(\.rawValue))

        #expect(Set(MigrationV1.walletKinds) == current, Self.hint)
        #expect(Set(MigrationV15.walletKinds) == current, Self.hint)
    }

    @Test
    func categoryKindsMatchCurrentCases() {
        let current = Set(EntryCategory.Kind.allCases.map(\.rawValue))

        #expect(Set(MigrationV1.categoryKinds) == current, Self.hint)
    }

    @Test
    func frequenciesMatchCurrentCases() {
        let current = Set(Recurring.Frequency.allCases.map(\.rawValue))

        #expect(Set(MigrationV1.frequencies) == current, Self.hint)
        #expect(Set(MigrationV13.frequencies) == current, Self.hint)
    }

    @Test
    func entryKindsMatchCurrentCases() {
        let current = Set(Entry.Kind.allCases.map(\.rawValue))

        #expect(Set(MigrationV1.entryKinds) == current, Self.hint)
        #expect(Set(MigrationV13.entryKinds) == current, Self.hint)
    }

    @Test
    func settingKeysMatchCurrentCases() {
        let current = Set(Setting.Key.allCases.map(\.rawValue))

        #expect(Set(MigrationV1.settingKeys) == current, Self.hint)
    }
}
