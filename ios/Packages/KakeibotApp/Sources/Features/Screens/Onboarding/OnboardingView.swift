import Core
import DesignSystem
import Store
import SwiftUI

public struct OnboardingView: View {
    @State var model: OnboardingModel
    @State var path: [SetupItem] = []

    @State private var slide = PageSlide()
    @State private var appIcon = AppIconListModel()

    private let database: AppDatabase
    private let today: LocalDate
    private let onFinish: () -> Void

    public init(
        database: AppDatabase,
        today: LocalDate,
        onFinish: @escaping () -> Void
    ) {
        let model = OnboardingModel(database: database, today: today)

        _model = State(initialValue: model)

        self.database = database
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
                        database: database,
                        today: today,
                        appIcon: appIcon
                    )
                }
        }
        .task {
            await model.load()
        }
        .task {
            await model.setup.run()
        }
        .task(id: model.page) {
            await model.refreshPage()
        }
    }
}

private extension OnboardingView {
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

            if !model.isFirstPage {
                PrimaryButton(model.nextTitle) {
                    Task {
                        await next()
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .background {
            Rectangle()
                .fill(Palette.background)
                .ignoresSafeArea()
        }
        .budgetKeypad(model.budget)
        .sensoryFeedback(.selection, trigger: model.page)
    }

    var topBar: some View {
        HStack {
            if model.isFirstPage {
                Color.clear
                    .frame(width: 44, height: 44)
            } else {
                RingButton(systemImage: "chevron.left") {
                    turnPage(.backward)
                }
            }

            Spacer()

            if !model.isFirstPage {
                PageDots(
                    count: model.pages.count,
                    current: model.pages.firstIndex(of: model.page) ?? 0
                )
            }

            Spacer()

            if model.isFirstPage {
                Color.clear
                    .frame(width: 44, height: 44)
            } else {
                Button("あとで決める") {
                    Task {
                        await finish()
                    }
                }
                .textFont(.footnote)
                .foregroundStyle(Palette.subtext)
                .frame(minWidth: 44, minHeight: 44)
            }
        }
    }

    @ViewBuilder
    var page: some View {
        switch model.page {
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

            routeButton(
                .minimal,
                title: "予算だけ決めて始める",
                detail: "月の始まりと予算",
                duration: "1 分"
            )

            routeButton(
                .full,
                title: "しっかり決めて始める",
                detail: "口座・固定費・通知・見た目なども",
                duration: "5 分"
            )

            PrimaryButton("すぐ始める") {
                Task {
                    model.choose(.quick)
                    await finish()
                }
            }

            Text("どれも、あとで設定から変えられます")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity)
    }

    func routeButton(
        _ route: OnboardingModel.Route,
        title: String,
        detail: String,
        duration: String
    ) -> some View {
        Button {
            model.choose(route)
            turnPage(.forward)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .textFont(.subheadline)
                        .foregroundStyle(Palette.text)

                    Text(detail)
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                }

                Spacer()

                Text(duration)
                    .textFont(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(Palette.hint)

                Image(systemName: "chevron.right")
                    .sansFont(.small)
                    .foregroundStyle(Palette.hint)
            }
            .frame(minHeight: 56)
            .padding(.horizontal, 16)
            .card()
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private extension OnboardingView {
    func next() async {
        guard model.isLastPage else {
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
