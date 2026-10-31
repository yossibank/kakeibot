import Features
import Store

extension AppModel {
    func observePro(in database: AppDatabase) async {
        let status = await proStore.status()
        await apply(status, in: database)

        for await status in proStore.updates() {
            await apply(status, in: database)
        }
    }
}

private extension AppModel {
    static let stopSyncFailedMessage = "同期を止められませんでした。設定の「同期と共有」から止めてください"

    func apply(
        _ status: ProStatus,
        in database: AppDatabase
    ) async {
        isPro = status.isUnlocked

        guard status == .revoked else {
            return
        }

        do {
            guard try await database.isSyncEnabled() else {
                return
            }

            try await database.turnOffSync()
        } catch {
            notice.show(Self.stopSyncFailedMessage)
        }
    }
}
