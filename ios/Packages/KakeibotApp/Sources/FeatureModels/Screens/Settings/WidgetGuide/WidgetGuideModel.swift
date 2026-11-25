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
    @MainActor
    @Observable
    final class State {
        public var place: WidgetGuidePlace

        public private(set) var sample: WidgetGuideSample
        public private(set) var shownSample: WidgetGuideSample?

        init(
            place: WidgetGuidePlace,
            sample: WidgetGuideSample
        ) {
            self.place = place
            self.sample = sample
        }

        public func show(_ sample: WidgetGuideSample?) {
            if shownSample != sample {
                shownSample = sample
            }

            if let sample,
               self.sample != sample {
                self.sample = sample
            }
        }

        public func showChosenSample() {
            show(sample)
        }
    }
}
