import FeatureModels
import Features
import Store

extension AppModel {
    func observePro(in database: AppDatabase) async {
        let status = await dependencies.proStore.status()
        await apply(status, in: database)

        if !status.isUnlocked {
            let store = dependencies.proStore

            Task {
                _ = try? await store.price()
            }
        }

        for await status in dependencies.proStore.updates() {
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
        input.isPro = status.isUnlocked

        guard status == .revoked else {
            return
        }

        do {
            guard try await database.isSyncEnabled() else {
                return
            }

            try await database.turnOffSync()
        } catch {
            state.notice.show(Self.stopSyncFailedMessage)
        }
    }
}
