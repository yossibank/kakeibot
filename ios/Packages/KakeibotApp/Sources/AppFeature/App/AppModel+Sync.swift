import CloudKit
import DesignSystem
import FeatureModels
import Foundation
import OSLog
import Store
import Sync

extension AppModel {
    func syncChanges() async {
        guard let database = state.launch.database else {
            return
        }

        await runtime.syncEngine?.stop()
        await runtime.sharedSyncEngine?.stop()
        runtime.syncEngine = nil
        runtime.sharedSyncEngine = nil

        guard input.syncActivity.isActive else {
            return
        }

        let engine = SyncEngine(database: database, scope: .private)
        let sharedEngine = SyncEngine(database: database, scope: .shared)

        runtime.syncEngine = engine
        runtime.sharedSyncEngine = sharedEngine
        await engine.start(isSyncEnabled: input.syncActivity.isSyncEnabled)
        await sharedEngine.start(isSyncEnabled: input.syncActivity.isSyncEnabled)

        await withDiscardingTaskGroup { group in
            group.addTask {
                await engine.fetchChanges()
            }

            group.addTask {
                await sharedEngine.fetchChanges()
            }

            group.addTask {
                await self.enqueueSyncChanges(
                    in: database,
                    engine: engine,
                    sharedEngine: sharedEngine
                )
            }
        }
    }

    func acceptShares() async {
        guard let database = state.launch.database else {
            return
        }

        let shares = dependencies.shareInbox.take()

        guard !shares.isEmpty else {
            return
        }

        for metadata in shares {
            do {
                try await SyncEngine.acceptShare(metadata)
                state.notices.error.inform(Self.joinedMessage(for: metadata))
            } catch is CancellationError {
                continue
            } catch {
                let code = error as NSError
                let detail = String(describing: error)

                Self.logger.error(
                    "\(Self.shareFailedMessage, privacy: .public) \(code.domain, privacy: .public) \(code.code) \(detail)"
                )

                state.notices.error.show(Self.shareFailedMessage)
            }
        }

        let engine = runtime.sharedSyncEngine ?? SyncEngine(database: database, scope: .shared)

        runtime.sharedSyncEngine = engine
        await engine.start(isSyncEnabled: input.syncActivity.isSyncEnabled)
        await engine.fetchChanges()
    }
}

private extension AppModel {
    static let shareFailedMessage = "共有の口座に参加できませんでした"
    static let shareJoinedMessage = "共有の口座に参加しました"
    static let logger = Logger(subsystem: "com.yossibank.kakeibot", category: "Sharing")

    static func joinedMessage(for metadata: CKShare.Metadata) -> String {
        guard
            let title = metadata.share[CKShare.SystemFieldKey.title] as? String,
            !title.isEmpty
        else {
            return shareJoinedMessage
        }

        return "「\(title)」に参加しました"
    }

    func enqueueSyncChanges(
        in database: AppDatabase,
        engine: SyncEngine,
        sharedEngine: SyncEngine
    ) async {
        await watch(database.syncChangeUpdates()) {
            await engine.enqueuePending()
            await sharedEngine.enqueuePending()
        }
    }
}
