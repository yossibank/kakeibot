import Core
import Foundation
import Observation

public extension ReviewModel {
    struct Presented: ScreenEditable {
        public var sheet = Shown<Sheet>()
        public var analysisShare = Shown<Share>()

        public internal(set) var pending: Opening?
    }

    @MainActor
    struct Notices: ScreenNotices {
        public let error: ErrorNotice

        init(wait: ScreenWait) {
            self.error = ErrorNotice(wait: wait)
        }
    }

    @MainActor
    @Observable
    final class State: NoticesHolding {
        public var presented = Presented()

        public let notices: Notices

        public private(set) var cursor = PeriodCursor()

        public internal(set) var reasonRequests = CommentRequests()
        public internal(set) var noteRequests = CommentRequests()

        init(wait: ScreenWait) {
            self.notices = Notices(wait: wait)
        }
    }
}

extension ReviewModel.State {
    func restart(movingForward isMovingForward: Bool) {
        cursor.restart(movingForward: isMovingForward)
    }

    func move(by count: Int) {
        guard cursor.canMove(by: count) else {
            return
        }

        cursor.move(by: count)
    }

    func moveToCurrent() {
        guard cursor.offset < 0 else {
            return
        }

        cursor.moveToCurrent()
    }
}
