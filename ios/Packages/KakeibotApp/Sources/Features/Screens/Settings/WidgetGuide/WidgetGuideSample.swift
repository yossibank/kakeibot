struct WidgetGuideSample: Hashable {
    let widget: WidgetGuideWidget
    let size: WidgetGuideSize
}

extension WidgetGuideSample {
    static let all = [
        WidgetGuideSample(widget: .quickRecord, size: .medium),
        WidgetGuideSample(widget: .quickRecord, size: .large),
        WidgetGuideSample(widget: .budget, size: .small),
        WidgetGuideSample(widget: .budget, size: .medium)
    ]
}
