import DesignSystem
import SwiftUI

public struct WidgetGuideView: View {
    @State private var place: WidgetGuidePlace

    public init() {
        self.init(place: .home)
    }

    init(place: WidgetGuidePlace) {
        _place = State(initialValue: place)
    }

    public var body: some View {
        VStack(spacing: SettingsSpacing.header) {
            SettingsBackHeader("ウィジェットの置き方")

            ScrollView {
                VStack(alignment: .leading, spacing: SettingsSpacing.section) {
                    WidgetGuideIntroCard()

                    VStack(spacing: 16) {
                        CapsulePicker(selection: $place, options: Self.options)

                        WidgetGuideStage(place: place)
                            .id(place)
                            .transition(.opacity)
                    }
                    .animation(.snappy, value: place)

                    abilities

                    steps
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 20)
        .padding(.top, SettingsSpacing.top)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            Backdrop()
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private extension WidgetGuideView {
    static let options = WidgetGuidePlace.allCases.map { place in
        CapsulePicker<WidgetGuidePlace>.Option(place.title, value: place)
    }
}

private extension WidgetGuideView {
    var abilities: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionTitle("できること")

            VStack(alignment: .leading, spacing: 14) {
                ForEach(place.abilities, id: \.self) { ability in
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
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionTitle("置き方")

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(place.steps.enumerated()), id: \.offset) { index, text in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 0) {
                            Text("\(index + 1)")
                                .textFont(.caption, weight: .bold)
                                .monospacedDigit()
                                .foregroundStyle(Palette.backgroundTop)
                                .frame(width: 24, height: 24)
                                .background(Palette.accent, in: Circle())

                            if index < place.steps.count - 1 {
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
                            .padding(.bottom, 14)

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

#Preview {
    NavigationStack {
        WidgetGuideView()
    }
}
