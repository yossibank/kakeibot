import Core

public extension ReviewModel {
    enum Sheet: Equatable, Sendable {
        case share(Share)
        case analysis
        case stamp(StampBook.Tally)
    }

    enum Opening: Equatable, Sendable {
        case entry(Entry.ID)
        case recurring(Recurring.ID)
        case day(LocalDate)
    }
}

public extension ReviewModel {
    func choose(
        _ id: Entry.ID,
        in share: Share
    ) {
        let isRecurring = share.id == Self.recurringShareId

        if isRecurring,
           let recurringId = output.recurringId(of: id) {
            state.open(afterSheet: .recurring(recurringId))
        } else {
            state.open(afterSheet: .entry(id))
        }
    }
}

public extension ReviewModel.Sheet {
    enum Key: Hashable {
        case share(AnyHashable)
        case analysis
        case stamp(Icon.ID)
    }
}

public extension ReviewModel.State {
    func open(afterSheet opening: ReviewModel.Opening) {
        pending = opening
        analysisShare.closeAll()
        presented.closeAll()
    }

    func takePending() -> ReviewModel.Opening? {
        guard let pending else {
            return nil
        }

        self.pending = nil

        return pending
    }
}

extension ReviewModel.Sheet: Identifiable {
    public var id: Key {
        switch self {
        case let .share(share): .share(share.id)
        case .analysis: .analysis
        case let .stamp(tally): .stamp(tally.id)
        }
    }
}
