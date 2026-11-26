import Core
import Foundation
import OSLog
import Store

public extension SyncModel {
    func open(_ item: WalletShare) async {
        guard item.isShared else {
            state.invitation = item
            return
        }

        let id = item.wallet.id

        state.opened = item
        input.members = .loading

        do {
            let participants = try await dependencies.cloud.participants(id, item.wallet.name)

            guard state.opened?.wallet.id == id else {
                return
            }

            input.members = .loaded(participants)
        } catch {
            guard state.opened?.wallet.id == id else {
                return
            }

            input.members = .failed
        }
    }

    func cancelInvitation() {
        state.invitation = nil
    }

    func closeOpened() {
        state.opened = nil
        input.members = .loading
    }

    func confirmInvitation() async {
        guard let item = state.invitation else {
            return
        }

        state.invitation = nil
        await show(item, creates: true)
    }

    func inviteMore() async {
        guard let item = state.opened else {
            return
        }

        closeOpened()
        await show(item, creates: false)
    }

    func stopSharing(_ item: WalletShare) async {
        await endShare(item.wallet.id)
    }

    func leave(_ item: JoinedShare) async {
        let id = item.wallet.id

        await workOnWallet(id, failure: Self.leaveFailedMessage) {
            try await dependencies.cloud.leaveShare(id, item.ownerName)
            try await dependencies.database.endSharing(id, at: dependencies.clock.now)
        }
    }
}

private extension SyncModel {
    static let shareFailedMessage = "共有を開けませんでした。時間をおいて試してください"
    static let inviteFailedMessage = "招待を保存できませんでした。時間をおいて試してください"
    static let stopFailedMessage = "共有を終えられませんでした。時間をおいて試してください"
    static let leaveFailedMessage = "共有から抜けられませんでした。時間をおいて試してください"
    static let logger = Logger(subsystem: "com.yossibank.kakeibot", category: "Sharing")

    func show(
        _ item: WalletShare,
        creates: Bool
    ) async {
        let id = item.wallet.id
        let name = item.wallet.name

        let onStop: SyncCloud.Stop = { [weak self] in
            await self?.endShare(id)
        }

        let onFail: SyncCloud.Fail = { [weak self] in
            self?.state.errorNotice.show(Self.inviteFailedMessage)
        }

        await workOnWallet(id, failure: Self.shareFailedMessage) {
            if creates {
                try await dependencies.cloud.createShare(id, name)
                try await dependencies.database.startSharing(id)
            }

            try await dependencies.cloud.showShare(id, name, onStop, onFail)
        }
    }

    func endShare(_ id: Wallet.ID) async {
        await workOnWallet(id, failure: Self.stopFailedMessage) {
            try await dependencies.cloud.deleteShare(id)
            try await dependencies.database.endSharing(id, at: dependencies.clock.now)
        }
    }

    func workOnWallet(
        _ id: Wallet.ID,
        failure: String,
        _ operation: () async throws -> Void
    ) async {
        state.workingWallet = id
        state.errorNotice.clear()

        do {
            try await operation()
        } catch {
            let code = error as NSError
            let detail = String(describing: error)

            Self.logger.error(
                "\(failure, privacy: .public) \(code.domain, privacy: .public) \(code.code) \(detail)"
            )

            state.errorNotice.show(failure, for: error)
        }

        if state.workingWallet == id {
            state.workingWallet = nil
        }
    }
}
