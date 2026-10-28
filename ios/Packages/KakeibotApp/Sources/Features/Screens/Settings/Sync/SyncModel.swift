import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class SyncModel {
    public private(set) var isOn = false
    public private(set) var isAvailable = true
    public private(set) var isWorking = false
    public private(set) var pendingCount: Int?

    public internal(set) var isChoosing = false
    public internal(set) var errorNotice = ErrorNotice()

    private let database: AppDatabase
    private let cloud: SyncCloud

    public init(
        database: AppDatabase,
        cloud: SyncCloud
    ) {
        self.database = database
        self.cloud = cloud
    }
}

public extension SyncModel {
    func load() async {
        do {
            isOn = try await database.isSyncEnabled()
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }

        isAvailable = await cloud.isAvailable()
    }

    func observePending() async {
        do {
            for try await count in database.pendingSyncCountUpdates() {
                pendingCount = count
            }
        } catch {
            pendingCount = nil
        }
    }

    func setOn(_ isOn: Bool) async {
        if isOn {
            await turnOn()
        } else {
            await work {
                try await database.turnOffSync()
            }
        }
    }

    func useCloudData() async {
        await work {
            try await database.turnOnSyncReplacingLocal()
        }
    }

    func useLocalData() async {
        await work {
            try await cloud.deleteData()
            try await database.turnOnSync()
        }
    }
}

private extension SyncModel {
    static let loadFailedMessage = "同期の状態を読み込めませんでした"
    static let saveFailedMessage = "同期を切り替えられませんでした。時間をおいて試してください"

    func turnOn() async {
        isAvailable = await cloud.isAvailable()

        guard isAvailable else {
            return
        }

        await work {
            guard try await cloud.hasData() else {
                try await database.turnOnSync()
                return
            }

            guard try await database.hasEntries() else {
                try await database.turnOnSyncReplacingLocal()
                return
            }

            isChoosing = true
        }
    }

    func work(_ operation: () async throws -> Void) async {
        isWorking = true
        errorNotice.clear()

        do {
            try await operation()

            isOn = try await database.isSyncEnabled()
        } catch {
            errorNotice.show(Self.saveFailedMessage)
        }

        isWorking = false
    }
}
