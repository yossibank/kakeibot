import Core
import Foundation
import OSLog
import Store

public extension SyncModel {
    func open(_ item: WalletShare) async {
        guard item.isShared else {
            state.presented.show(.invitation(item))
            return
        }

        let id = item.wallet.id

        state.presented.show(.opened(item))
        input.members = .loading

        do {
            let participants = try await dependencies.cloud.participants(id, item.wallet.name)

            guard output.opened?.wallet.id == id else {
                return
            }

            input.members = .loaded(participants)
        } catch {
            guard output.opened?.wallet.id == id else {
                return
            }

            input.members = .failed
        }
    }

    func cancelInvitation() {
        if let item = output.invitation {
            state.presented.close(.invitation(item))
        }
    }

    func closeOpened() {
        if let item = output.opened {
            state.presented.close(.opened(item))
        }

        input.members = .loading
    }

    func confirmInvitation() async {
        guard
            let item = output.invitation,
            !state.shareTask.isRunning
        else {
            return
        }

        state.presented.close(.invitation(item))
        await show(item, creates: true)
    }

    func inviteMore() async {
        guard
            let item = output.opened,
            !state.shareTask.isRunning
        else {
            return
        }

        closeOpened()
        await show(item, creates: false)
    }

    func stopSharing(_ item: WalletShare) async {
        guard !state.shareTask.isRunning else {
            return
        }

        await endShare(item.wallet.id)
    }

    func leave(_ item: JoinedShare) async {
        guard !state.shareTask.isRunning else {
            return
        }

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
            try await state.shareTask.attempt {
                try await operation()
            }
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
