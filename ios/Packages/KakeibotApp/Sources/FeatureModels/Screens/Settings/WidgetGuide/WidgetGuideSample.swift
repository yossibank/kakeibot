public struct WidgetGuideSample: Hashable, Sendable {
    public let widget: WidgetGuideWidget
    public let size: WidgetGuideSize

    public init(
        widget: WidgetGuideWidget,
        size: WidgetGuideSize
    ) {
        self.widget = widget
        self.size = size
    }
}

public extension WidgetGuideSample {
    static let all = [
        WidgetGuideSample(widget: .quickRecord, size: .medium),
        WidgetGuideSample(widget: .quickRecord, size: .large),
        WidgetGuideSample(widget: .budget, size: .small),
        WidgetGuideSample(widget: .budget, size: .medium)
    ]
}
