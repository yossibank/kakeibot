import DesignSystem
import SwiftUI

struct WhatsNewCard: View {
    @State private var shownSteps: Int
    @State private var stepsWidth: CGFloat = 0

    let feature: WhatsNewRelease.Feature
    let onTry: (WhatsNewRelease.Action) -> Void

    init(
        feature: WhatsNewRelease.Feature,
        revealsSteps: Bool,
        onTry: @escaping (WhatsNewRelease.Action) -> Void
    ) {
        _shownSteps = State(initialValue: revealsSteps ? 0 : feature.steps.count)

        self.feature = feature
        self.onTry = onTry
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: feature.systemImage)
                    .sansFont(.small, weight: .medium)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 38, height: 38)
                    .background(Palette.accent.opacity(.subtle), in: Circle())

                Text(feature.title)
                    .displayFont(.body, weight: .semibold)
                    .foregroundStyle(Palette.text)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Group {
                if stepsWidth >= wideStepsWidth {
                    VStack(spacing: 8) {
                        HStack(spacing: Self.gap) {
                            ForEach(indexedSteps, id: \.offset) { index, step in
                                if index > 0 {
                                    chevron(index)
                                }

                                WhatsNewScene(kind: step.scene)
                                    .frame(
                                        minWidth: Self.minSceneWidth,
                                        idealWidth: Self.minSceneWidth,
                                        maxWidth: .infinity
                                    )
                                    .modifier(StepReveal(isShown: isShown(index)))
                            }
                        }

                        HStack(alignment: .top, spacing: Self.gap) {
                            ForEach(indexedSteps, id: \.offset) { index, step in
                                if index > 0 {
                                    Color.clear
                                        .frame(width: Self.chevronWidth, height: 1)
                                }

                                caption(step, number: index + 1)
                                    .frame(
                                        minWidth: Self.minSceneWidth,
                                        idealWidth: Self.minSceneWidth,
                                        maxWidth: .infinity,
                                        alignment: .leading
                                    )
                                    .modifier(StepReveal(isShown: isShown(index)))
                            }
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(indexedSteps, id: \.offset) { index, step in
                            HStack(spacing: 12) {
                                WhatsNewScene(kind: step.scene)
                                    .frame(width: Self.listSceneWidth)

                                caption(step, number: index + 1)

                                Spacer(minLength: 0)
                            }
                            .modifier(StepReveal(isShown: isShown(index)))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { width in
                stepsWidth = width
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(feature.lead)
                    .textFont(.subheadline, weight: .semibold)
                    .foregroundStyle(Palette.text)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(feature.points, id: \.self) { point in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Palette.accent)

                        Text(point)
                            .foregroundStyle(Palette.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .textFont(.footnote)
                }
            }

            if let action = feature.action {
                CardButton(
                    feature.actionTitle,
                    style: .outlined(Palette.accent),
                    height: 40
                ) {
                    onTry(action)
                }
            }
        }
        .padding(16)
        .card()
        .task {
            await revealSteps()
        }
    }
}

private extension WhatsNewCard {
    struct StepReveal: ViewModifier {
        let isShown: Bool

        func body(content: Content) -> some View {
            content
                .opacity(isShown ? 1 : 0)
                .offset(y: isShown ? 0 : 10)
                .scaleEffect(isShown ? 1 : 0.94)
        }
    }

    static let minSceneWidth: CGFloat = 88
    static let listSceneWidth: CGFloat = 116
    static let chevronWidth: CGFloat = 8
    static let gap: CGFloat = 4
    static let stepDelay: Duration = .milliseconds(320)
}

private extension WhatsNewCard {
    var indexedSteps: [(offset: Int, element: WhatsNewRelease.Step)] {
        Array(feature.steps.enumerated())
    }

    var wideStepsWidth: CGFloat {
        let count = CGFloat(feature.steps.count)
        let joint = Self.chevronWidth + Self.gap * 2
        return Self.minSceneWidth * count + joint * max(count - 1, 0)
    }

    func isShown(_ index: Int) -> Bool {
        index < shownSteps
    }
}

private extension WhatsNewCard {
    func chevron(_ index: Int) -> some View {
        Image(systemName: "chevron.right")
            .textFont(.caption2, weight: .bold)
            .foregroundStyle(Palette.hint)
            .frame(width: Self.chevronWidth)
            .opacity(isShown(index) ? 1 : 0)
    }

    func caption(
        _ step: WhatsNewRelease.Step,
        number: Int
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("\(number)")
                .textFont(.caption2, weight: .bold)
                .monospacedDigit()
                .foregroundStyle(Palette.backgroundTop)
                .frame(width: 16, height: 16)
                .background(Palette.accent, in: Circle())

            Text(step.caption)
                .textFont(.caption2, weight: .medium)
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    func revealSteps() async {
        guard shownSteps < feature.steps.count else {
            return
        }

        for count in (shownSteps + 1)...feature.steps.count {
            do {
                try await Task.sleep(for: Self.stepDelay)
            } catch {
                return
            }

            withAnimation(.spring(duration: 0.45, bounce: 0.25)) {
                shownSteps = count
            }
        }
    }
}
