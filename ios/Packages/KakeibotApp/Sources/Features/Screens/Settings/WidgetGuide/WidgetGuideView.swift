import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct WidgetGuideView: View {
    @State private var model: WidgetGuideModel
    @State private var hintModel: SettingsHintModel

    public init(parts: ScreenParts) {
        self.init(parts: parts, place: .home)
    }

    init(
        parts: ScreenParts,
        place: WidgetGuidePlace,
        widget: WidgetGuideWidget = .quickRecord,
        size: WidgetGuideSize = .medium
    ) {
        let hintModel = SettingsHintModel(parts: parts, screen: .widgetGuide)

        let sample = WidgetGuideSample(widget: widget, size: size)

        _model = State(initialValue: WidgetGuideModel(place: place, sample: sample))
        _hintModel = State(initialValue: hintModel)
    }

    public var body: some View {
        VStack(spacing: SettingsSpacing.header) {
            SettingsBackHeader("ウィジェットの置き方", hint: hint)

            WidgetGuideIntroCard(hint: hint)

            ScrollView {
                VStack(alignment: .leading, spacing: SettingsSpacing.section) {
                    VStack(spacing: 16) {
                        CapsulePicker(
                            selection: Bindable(model.state).place,
                            options: Self.options,
                            size: .wide
                        )

                        if place == .home {
                            carousel
                        } else {
                            WidgetGuideStage(
                                place: place,
                                widget: widget,
                                size: size
                            )
                            .id(place)
                            .transition(.opacity)
                        }
                    }
                    .animation(.snappy, value: place)

                    abilities

                    steps
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, SettingsSpacing.side)
        .padding(.top, SettingsSpacing.top)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .backdrop()
        .toolbar(.hidden, for: .navigationBar)
    }
}

private extension WidgetGuideView {
    var carousel: some View {
        VStack(spacing: 12) {
            WidgetGuideStage(
                place: .home,
                widget: widget,
                size: size
            )
            .padding(.horizontal, Self.carouselMargin)
            .hidden()
            .overlay {
                GeometryReader { proxy in
                    ScrollView(.horizontal) {
                        HStack(alignment: .top, spacing: 8) {
                            ForEach(WidgetGuideSample.all, id: \.self) { item in
                                WidgetGuideStage(
                                    place: .home,
                                    widget: item.widget,
                                    size: item.size
                                )
                                .frame(width: proxy.size.width - Self.carouselMargin * 2)
                                .opacity(isCurrent(item) ? 1 : 0.35)
                                .id(item)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollPosition(id: shownSample)
                    .onAppear {
                        model.state.showChosenSample()
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .contentMargins(.horizontal, Self.carouselMargin)
                    .scrollIndicators(.hidden)
                }
            }

            Text("\(widget.title)・\(size.title)")
                .textFont(.subheadline, weight: .semibold)
                .foregroundStyle(Palette.text)

            HStack(spacing: 8) {
                ForEach(WidgetGuideSample.all, id: \.self) { item in
                    Circle()
                        .fill(isCurrent(item) ? Palette.accent : Palette.line)
                        .frame(width: 6, height: 6)
                }
            }
        }
    }

    var abilities: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionTitle("できること")

            VStack(alignment: .leading, spacing: 12) {
                ForEach(place.abilities(for: widget), id: \.self) { ability in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: ability.systemImage)
                            .sansFont(.small, weight: .medium)
                            .foregroundStyle(Palette.accent)
                            .frame(width: 34, height: 34)
                            .background(Palette.accent.opacity(.subtle), in: Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(ability.title)
                                .textFont(.subheadline, weight: .semibold)
                                .foregroundStyle(Palette.text)

                            Text(ability.detail)
                                .textFont(.caption)
                                .foregroundStyle(Palette.subtext)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(16)
            .card()
        }
    }

    var steps: some View {
        let texts = place.steps(for: widget, size: size)

        return VStack(alignment: .leading, spacing: 8) {
            SettingsSectionTitle("置き方")

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(texts.enumerated()), id: \.offset) { index, text in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 0) {
                            Text("\(index + 1)")
                                .textFont(.caption, weight: .bold)
                                .monospacedDigit()
                                .foregroundStyle(Palette.backgroundTop)
                                .frame(width: 24, height: 24)
                                .background(Palette.accent, in: Circle())

                            if index < texts.count - 1 {
                                Rectangle()
                                    .fill(Palette.outline)
                                    .frame(width: 1.5)
                                    .frame(minHeight: 14, maxHeight: .infinity)
                            }
                        }

                        Text(text)
                            .textFont(.subheadline)
                            .foregroundStyle(Palette.text)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 2)
                            .padding(.bottom, 12)

                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 2)
            .card()
        }
    }
}

private extension WidgetGuideView {
    static let carouselMargin: CGFloat = 16

    static let options = WidgetGuidePlace.allCases.map { place in
        CapsulePicker<WidgetGuidePlace>.Option(place.title, value: place)
    }

    var place: WidgetGuidePlace {
        model.state.place
    }

    var widget: WidgetGuideWidget {
        model.state.sample.widget
    }

    var size: WidgetGuideSize {
        model.state.sample.size
    }

    var shownSample: Binding<WidgetGuideSample?> {
        Binding {
            model.state.shownSample
        } set: { sample in
            model.state.show(sample)
        }
    }

    var hint: SettingsFold {
        SettingsFold(\.hint, in: hintModel)
    }

    func isCurrent(_ item: WidgetGuideSample) -> Bool {
        item == model.state.sample
    }
}

#Preview {
    if let parts = ScreenParts.preview() {
        NavigationStack {
            WidgetGuideView(parts: parts)
        }
    }
}
