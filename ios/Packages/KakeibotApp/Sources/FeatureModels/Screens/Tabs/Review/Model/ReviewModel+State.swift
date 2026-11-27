import Core
import Foundation
import Observation

public extension ReviewModel {
    struct Presented: ScreenEditable {
        public var sheet = Shown<Sheet>()
        public var analysisShare = Shown<Share>()
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

        public internal(set) var checkTime: Date
        public internal(set) var pending: Opening?

        public private(set) var offset = 0
        public private(set) var isMovingForward = true

        public internal(set) var showsStoreReviewCard = false
        public internal(set) var newReportKey: String?

        init(
            checkTime: Date,
            wait: ScreenWait
        ) {
            self.notices = Notices(wait: wait)
            self.checkTime = checkTime
        }
    }
}

extension ReviewModel.State {
    func restart(movingForward isMovingForward: Bool) {
        self.isMovingForward = isMovingForward
        offset = 0
    }

    func move(by count: Int) {
        guard offset + count <= 0 else {
            return
        }

        isMovingForward = count > 0
        offset += count
    }

    func moveToCurrent() {
        guard offset < 0 else {
            return
        }

        isMovingForward = true
        offset = 0
    }
}
