import Core
import Foundation
import OSLog
import Store

public extension SyncModel {
    func open(_ item: WalletShare) async {
        guard item.isShared else {
            invitation = item
            return
        }

        let id = item.wallet.id

        opened = item
        participants = nil
        isParticipantsFailed = false

        do {
            let participants = try await cloud.participants(id, item.wallet.name)

            guard opened?.wallet.id == id else {
                return
            }

            self.participants = participants
        } catch {
            guard opened?.wallet.id == id else {
                return
            }

            isParticipantsFailed = true
        }
    }

    func cancelInvitation() {
        invitation = nil
    }

    func closeOpened() {
        opened = nil
        participants = nil
        isParticipantsFailed = false
    }

    func confirmInvitation() async {
        guard let item = invitation else {
            return
        }

        invitation = nil

        await show(item, creates: true)
    }

    func inviteMore() async {
        guard let item = opened else {
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
            try await cloud.leaveShare(id, item.ownerName)
            try await database.endSharing(id)
        }
    }
}

private extension SyncModel {
    static let shareFailedMessage = "共有を開けませんでした。時間をおいて試してください"
    static let inviteFailedMessage = "招待を保存できませんでした。時間をおいて試してください"
    static let stopFailedMessage = "共有をやめられませんでした。時間をおいて試してください"
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
            self?.errorNotice.show(Self.inviteFailedMessage)
        }

        await workOnWallet(id, failure: Self.shareFailedMessage) {
            if creates {
                try await cloud.createShare(id, name)
                try await database.startSharing(id)
            }

            try await cloud.showShare(id, name, onStop, onFail)
        }
    }

    func endShare(_ id: Wallet.ID) async {
        await workOnWallet(id, failure: Self.stopFailedMessage) {
            try await cloud.deleteShare(id)
            try await database.endSharing(id)
        }
    }

    func workOnWallet(
        _ id: Wallet.ID,
        failure: String,
        _ operation: () async throws -> Void
    ) async {
        workingWallet = id
        errorNotice.clear()

        do {
            try await operation()
        } catch {
            let code = error as NSError
            let detail = String(describing: error)

            Self.logger.error(
                "\(failure, privacy: .public) \(code.domain, privacy: .public) \(code.code) \(detail)"
            )
            errorNotice.show(failure, for: error)
        }

        if workingWallet == id {
            workingWallet = nil
        }
    }
}
