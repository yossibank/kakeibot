import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct OnboardingView: View {
    @State var model: OnboardingModel
    @State var path: [SetupItem] = []

    @State private var slide = PageSlide()
    @State private var appIcon = AppIconListModel()

    private let parts: ScreenParts
    private let today: LocalDate
    private let onFinish: () -> Void

    public init(
        parts: ScreenParts,
        today: LocalDate,
        onFinish: @escaping () -> Void
    ) {
        let model = OnboardingModel(
            parts: parts,
            today: today,
            newsVersion: WhatsNewRelease.latestVersion
        )

        _model = State(initialValue: model)

        self.parts = parts
        self.today = today
        self.onFinish = onFinish
    }

    public var body: some View {
        NavigationStack(path: $path) {
            content
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: SetupItem.self) { item in
                    SetupDestination(
                        item,
                        parts: parts,
                        today: today,
                        appIcon: appIcon
                    )
                }
        }
        .task {
            await model.load()
        }
        .task {
            await model.state.setup.run()
        }
        .task(id: model.state.page) {
            await model.refreshPage()
        }
    }
}

private extension OnboardingView {
    static let contentWidth: CGFloat = 580

    var content: some View {
        VStack(spacing: 20) {
            topBar

            page
                .pageSlide(slide)
                .frame(maxHeight: .infinity, alignment: .top)
                .contentShape(.rect)
                .onPageSwipe(following: $slide) { direction in
                    model.canTurn(forward: direction == .forward)
                } perform: { direction in
                    turnPage(direction)
                }

            if !model.output.isFirstPage {
                PrimaryButton(model.output.nextTitle) {
                    Task {
                        await next()
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: Self.contentWidth, maxHeight: .infinity, alignment: .top)
        .frame(maxWidth: .infinity)
        .errorBanner(Bindable(model.state).errorNotice)
        .backdrop()
        .budgetKeypad(model.state.budget)
        .haptic(.selection, trigger: model.state.page)
    }

    var topBar: some View {
        HStack {
            if model.output.isFirstPage {
                Color.clear
                    .frame(width: 44, height: 44)
            } else {
                RingButton(systemImage: "chevron.left") {
                    turnPage(.backward)
                }
            }

            Spacer()

            if !model.output.isFirstPage {
                PageDots(
                    count: model.output.stepPages.count,
                    current: model.output.stepPages.firstIndex(of: model.state.page) ?? 0
                )
            }

            Spacer()

            if model.output.isFirstPage {
                Color.clear
                    .frame(width: 44, height: 44)
            } else {
                Button("設定を飛ばして始める") {
                    Task {
                        await finish()
                    }
                }
                .textFont(.footnote)
                .foregroundStyle(Palette.subtext)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(minWidth: 44, minHeight: 44)
            }
        }
    }

    @ViewBuilder
    var page: some View {
        switch model.state.page {
        case .welcome: welcomePage
        case .monthStart: monthStartPage
        case .budget: budgetPage
        case .setup: setupPage
        }
    }

    var welcomePage: some View {
        VStack(spacing: 12) {
            Spacer()

            VStack(spacing: 12) {
                Text("ようこそ")
                    .displayFont(.title)
                    .tracking(8)
                    .foregroundStyle(Palette.accent)

                Text("毎日の記録を、すばやく、心地よく")
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.accentStrong)
            }

            Spacer()

            VStack(spacing: 0) {
                routeRow(
                    systemImage: "gearshape",
                    title: "しっかり決めて始める",
                    detail: "口座・固定費・通知・見た目",
                    duration: "5 分"
                ) {
                    model.choose(.full)
                    turnPage(.forward)
                }

                Hairline()
                    .padding(.leading, 52)

                routeRow(
                    systemImage: "bolt",
                    title: "決めずに始める",
                    detail: "設定はあとで",
                    duration: nil
                ) {
                    Task {
                        model.choose(.quick)
                        await finish()
                    }
                }
            }
            .card()

            PrimaryButton("予算を決めて始める", detail: "1 分") {
                model.choose(.minimal)
                turnPage(.forward)
            }

            Text("どれも、あとで設定から変えられます")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity)
    }

    func routeRow(
        systemImage: String,
        title: String,
        detail: String,
        duration: String?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .sansFont(.body, weight: .light)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .textFont(.subheadline)
                        .foregroundStyle(Palette.text)

                    Text(detail)
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                }

                Spacer()

                if let duration {
                    Text(duration)
                        .textFont(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(Palette.hint)
                }

                DisclosureMark()
            }
            .frame(minHeight: 56)
            .padding(.horizontal, 16)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private extension OnboardingView {
    func next() async {
        guard model.output.isLastPage else {
            turnPage(.forward)
            return
        }

        await finish()
    }

    func turnPage(_ direction: PageSwipeDirection) {
        let forward = direction == .forward

        guard model.canTurn(forward: forward) else {
            return
        }

        PageSlide.run($slide, forward: forward) {
            switch direction {
            case .forward: model.next()
            case .backward: model.back()
            }
        }
    }

    func finish() async {
        if await model.finish() {
            onFinish()
        }
    }
}
