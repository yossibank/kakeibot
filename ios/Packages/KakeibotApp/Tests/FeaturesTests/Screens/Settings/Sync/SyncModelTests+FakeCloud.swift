import Features
import Store

extension SyncModelTests {
    actor FakeCloud {
        private(set) var deleted = false
        private(set) var shareCalls: [String] = []

        private var account: SyncAccount
        private let hasData: Bool
        private let cloudSummary: SyncSummary
        private let participants: [SyncParticipant]
        private let stopsInSheet: Bool
        private let failsInSheet: Bool
        private let failsToSummarize: Bool
        private let failsToDeleteData: Bool
        private let failsToCreate: Bool
        private let failsToList: Bool
        private let failsToDelete: Bool
        private let failsToLeave: Bool

        init(
            account: SyncAccount = .available,
            hasData: Bool,
            cloudSummary: SyncSummary = SyncSummary(entryCount: 0, updatedAt: nil),
            participants: [SyncParticipant] = [],
            stopsInSheet: Bool = false,
            failsInSheet: Bool = false,
            failsToSummarize: Bool = false,
            failsToDeleteData: Bool = false,
            failsToCreate: Bool = false,
            failsToList: Bool = false,
            failsToDelete: Bool = false,
            failsToLeave: Bool = false
        ) {
            self.account = account
            self.hasData = hasData
            self.cloudSummary = cloudSummary
            self.participants = participants
            self.stopsInSheet = stopsInSheet
            self.failsInSheet = failsInSheet
            self.failsToSummarize = failsToSummarize
            self.failsToDeleteData = failsToDeleteData
            self.failsToCreate = failsToCreate
            self.failsToList = failsToList
            self.failsToDelete = failsToDelete
            self.failsToLeave = failsToLeave
        }
    }
}

extension SyncModelTests.FakeCloud {
    nonisolated var cloud: SyncCloud {
        SyncCloud {
            await self.account
        } summary: {
            if self.failsToSummarize {
                throw CancellationError()
            }

            return self.hasData ? self.cloudSummary : nil
        } deleteData: {
            try await self.delete()
        } createShare: { _, _ in
            try await self.createShare()
        } showShare: { _, _, onStop, onFail in
            await self.record("show")

            if self.failsInSheet {
                onFail()
            }

            if self.stopsInSheet {
                await onStop()
            }
        } participants: { _, _ in
            try await self.listParticipants()
        } deleteShare: { _ in
            try await self.deleteShare()
        } leaveShare: { _, owner in
            try await self.leaveShare(owner)
        }
    }

    func delete() throws {
        if failsToDeleteData {
            throw CancellationError()
        }

        deleted = true
    }

    func signIn() {
        account = .available
    }

    func record(_ call: String) {
        shareCalls.append(call)
    }

    func listParticipants() throws -> [SyncParticipant] {
        shareCalls.append("list")

        if failsToList {
            throw CancellationError()
        }

        return participants
    }

    func deleteShare() throws {
        shareCalls.append("delete")

        if failsToDelete {
            throw CancellationError()
        }
    }

    func leaveShare(_ owner: String) throws {
        shareCalls.append("leave \(owner)")

        if failsToLeave {
            throw CancellationError()
        }
    }

    func createShare() throws {
        shareCalls.append("create")

        if failsToCreate {
            throw CancellationError()
        }
    }
}
