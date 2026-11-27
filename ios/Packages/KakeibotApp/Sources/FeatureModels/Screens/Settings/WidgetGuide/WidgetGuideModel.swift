import Observation

@MainActor
@Observable
public final class WidgetGuideModel {
    public let state: State

    public init(
        place: WidgetGuidePlace = .home,
        sample: WidgetGuideSample = WidgetGuideSample(widget: .quickRecord, size: .medium)
    ) {
        self.state = State(place: place, sample: sample)
    }
}

public extension WidgetGuideModel {
    struct Presented: ScreenEditable {
        public var place: WidgetGuidePlace

        public internal(set) var shownSample: WidgetGuideSample?
    }

    @MainActor
    @Observable
    final class State {
        public var presented: Presented

        public private(set) var sample: WidgetGuideSample

        init(
            place: WidgetGuidePlace,
            sample: WidgetGuideSample
        ) {
            self.presented = Presented(place: place)
            self.sample = sample
        }
    }
}

public extension WidgetGuideModel.State {
    func show(_ sample: WidgetGuideSample?) {
        if presented.shownSample != sample {
            presented.shownSample = sample
        }

        if let sample,
           self.sample != sample {
            self.sample = sample
        }
    }

    func showChosenSample() {
        show(sample)
    }
}
