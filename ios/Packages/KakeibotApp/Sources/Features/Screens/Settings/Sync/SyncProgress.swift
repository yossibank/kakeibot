import Foundation
import Store

public enum SyncProgress: Hashable, Sendable {
    case switching
    case checking
    case receiving
    case sending(Int)
    case stuck(SyncSendProblem, Int)
    case upToDate(Date?)
    case stopped(SyncStopReason)
}

public extension SyncProgress {
    var isBusy: Bool {
        switch self {
        case .switching, .checking, .receiving, .sending: true
        case .stuck, .upToDate, .stopped: false
        }
    }

    var isProblem: Bool {
        switch self {
        case .stuck, .stopped: true
        case .switching, .checking, .receiving, .sending, .upToDate: false
        }
    }

    var message: String {
        switch self {
        case .switching: "切り替えています…"
        case .checking: "iCloud の状態を確かめています…"
        case .receiving: "iCloud から受け取っています…"
        case let .sending(count): "iCloud に送っています（残り \(count) 件）"
        case let .stuck(problem, count): "\(problem.message)（残り \(count) 件）"
        case let .upToDate(date): Self.upToDateMessage(date)
        case let .stopped(reason): reason.message
        }
    }
}

private extension SyncProgress {
    static func upToDateMessage(_ date: Date?) -> String {
        guard let date else {
            return "最新の状態です"
        }

        let time = date.formatted(.dateTime.hour().minute())
        return "最新の状態です（\(time) に同期）"
    }
}
