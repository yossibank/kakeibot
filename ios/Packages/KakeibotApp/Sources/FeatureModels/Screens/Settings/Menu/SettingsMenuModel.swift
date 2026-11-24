import Core
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class SettingsMenuModel {
    public let input = Input()

    let dependencies: ScreenParts

    public init(parts: ScreenParts) {
        self.dependencies = parts
    }
}

public extension SettingsMenuModel {
    @MainActor
    @Observable
    final class Input {
        public internal(set) var monthStartDay: MonthStartDay = .first
        public internal(set) var launchScreen: LaunchScreen = .home
        public internal(set) var reminderTime: ReminderTime?
        public internal(set) var theme: ThemeChoice = .system
        public internal(set) var customThemes: [Theme] = []
        public internal(set) var syncStatus = SyncStatus.off
        public internal(set) var backupExportedAt: Date?
        public internal(set) var firstEntryCreatedAt: Date?
        public internal(set) var usesFun: Bool?
    }

    func run() async {
        let database = dependencies.database

        await ScreenObservation.all([
            {
                await self.follow(
                    database.settingUpdates(.monthStartDay),
                    into: \.monthStartDay,
                    fallback: .first
                )
            },
            {
                await self.follow(
                    database.settingUpdates(.launchScreen),
                    into: \.launchScreen,
                    fallback: .home
                )
            },
            {
                await self.follow(
                    database.settingUpdates(.reminderTime),
                    into: \.reminderTime,
                    fallback: nil
                )
            },
            {
                await self.follow(database.settingUpdates(.theme), into: \.theme, fallback: .system)
            },
            {
                await self.follow(database.customThemeUpdates(), into: \.customThemes, fallback: [])
            },
            {
                await self.follow(database.syncStatusUpdates(), into: \.syncStatus, fallback: .off)
            },
            {
                await self.follow(
                    database.settingUpdates(.backupExportedAt),
                    into: \.backupExportedAt,
                    fallback: nil
                )
            },
            {
                await self.loadFirstEntryCreatedAt()
            },
            {
                await self.loadUsesFun()
            }
        ])
    }

    func weekStartModel() -> SettingsMenuValueModel<Weekday> {
        SettingsMenuValueModel(parts: dependencies, key: .weekStart)
    }

    func resetModel() -> SettingsMenuResetModel {
        SettingsMenuResetModel(parts: dependencies)
    }

    func backupText() -> String? {
        guard !input.syncStatus.isEnabled else {
            return nil
        }

        return BackupModel.exportAgeText(
            exportedAt: input.backupExportedAt,
            firstCreatedAt: input.firstEntryCreatedAt,
            now: dependencies.clock.now
        )
    }
}

private extension SettingsMenuModel {
    func follow<Value>(
        _ updates: some AsyncSequence<Value, any Error>,
        into keyPath: ReferenceWritableKeyPath<Input, Value>,
        fallback: Value
    ) async {
        do {
            for try await value in updates {
                input[keyPath: keyPath] = value
            }
        } catch {
            input[keyPath: keyPath] = fallback
        }
    }

    func loadFirstEntryCreatedAt() async {
        input.firstEntryCreatedAt = try? await dependencies.database.entryHistory().firstCreatedAt
    }

    func loadUsesFun() async {
        do {
            let calendar = try await dependencies.database.stampBook()
            let rules = try await dependencies.database.rewardRuleList()

            input.usesFun = !calendar.stamps.isEmpty || !rules.rules.isEmpty
        } catch {
            input.usesFun = true
        }
    }
}
