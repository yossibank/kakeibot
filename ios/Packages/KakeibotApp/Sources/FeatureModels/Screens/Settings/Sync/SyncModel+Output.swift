import Core
import Foundation
import Store

public extension SyncModel {
    @MainActor
    final class Output {
        let input: Input
        let state: State

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }
    }
}

public extension SyncModel.Output {
    var isAvailable: Bool {
        input.account == .available
    }

    var pendingCount: Int? {
        input.pending.value
    }

    var isPendingFailed: Bool {
        input.pending.isFailed
    }

    var participants: [SyncParticipant]? {
        input.members.value
    }

    var isParticipantsFailed: Bool {
        input.members.isFailed
    }

    var choice: SyncChoice? {
        state.presented.current?.choice
    }

    var invitation: WalletShare? {
        state.presented.current?.invitation
    }

    var opened: WalletShare? {
        state.presented.current?.opened
    }

    var isChoosing: Bool {
        choice != nil
    }

    var shownOn: Bool {
        state.requestedOn ?? input.isOn
    }

    var isSwitching: Bool {
        state.requestedOn != nil
    }

    var progress: SyncProgress? {
        if state.task.isRunning {
            return .switching
        }

        guard input.isOn else {
            return input.stopReason.map(SyncProgress.stopped)
        }

        guard let pendingCount else {
            return isPendingFailed ? nil : .checking
        }

        if input.isFetching {
            return .receiving
        }

        guard pendingCount > 0 else {
            return .upToDate(input.syncedAt)
        }

        return input.sendProblem.map { .stuck($0, pendingCount) } ?? .sending(pendingCount)
    }

    var footnote: String {
        guard !input.isOn else {
            return "切っても、この \(DeviceName.current) のデータは残ります。"
        }

        return switch input.account {
        case .available: "オンにすると、ほかの端末と記録がそろいます。"
        case .noAccount: "設定アプリで iCloud にサインインすると使えます。"
        case .restricted: "この \(DeviceName.current) では、制限で iCloud を使えません。"
        case .temporarilyUnavailable: "設定アプリで iCloud にサインインし直すと使えます。"
        case .couldNotDetermine: "iCloud の状態を確かめられませんでした。\n時間をおいて開き直してください。"
        }
    }
}
