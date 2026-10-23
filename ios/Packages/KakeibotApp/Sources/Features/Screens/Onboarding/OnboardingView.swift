import Core
import DesignSystem
import Store
import SwiftUI

public struct OnboardingView: View {
    @State private var model: OnboardingModel
    @State private var slide = PageSlide()
    @State private var path: [SetupItem] = []
    @State private var appIcon = AppIconListModel()

    private let database: AppDatabase
    private let today: LocalDate
    private let onFinish: () -> Void

    public init(
        database: AppDatabase,
        today: LocalDate,
        onFinish: @escaping () -> Void
    ) {
        _model = State(
            initialValue: OnboardingModel(database: database, today: today)
        )

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
                Button("スキップ") {
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
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("ようこそ")
                    .displayFont(.title)
                    .tracking(8)
                    .foregroundStyle(Palette.accent)

                Text("毎日の記録を、すばやく、心地よく")
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.accentStrong)
            }
            .padding(.top, 36)

            VStack(spacing: 12) {
                PrimaryButton("すぐ始める") {
                    Task {
                        model.choose(.quick)
                        await finish()
                    }
                }

                routeButton(
                    .minimal,
                    title: "予算だけ決めて始める",
                    detail: "月の始まりと予算",
                    duration: "1 分"
                )

                routeButton(
                    .full,
                    title: "しっかり決めて始める",
                    detail: "口座・固定費・通知なども",
                    duration: "5 分"
                )
            }

            Text("どれも、あとで設定から変えられます")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)
        }
    }

    var monthStartPage: some View {
        ScrollView {
            VStack(spacing: 20) {
                pageHeader(
                    "月と週の始まり",
                    message: "給料日に合わせると、給料日から\n次の給料日の前の日までを 1 か月として数えます"
                )

                PeriodCard(
                    periodText: model.monthStart.periodText,
                    month: model.monthStart.month
                )

                MonthStartDayGrid(selection: model.monthStart.startDay) { day in
                    Task {
                        await model.monthStart.choose(day)
                    }
                }

                HStack(spacing: 12) {
                    Text("週の始まり")
                        .textFont(.subheadline)
                        .foregroundStyle(Palette.text)

                    Spacer()

                    CapsulePicker(
                        selection: weekStartBinding,
                        options: Weekday.weekStartOptions
                    )
                }
                .frame(minHeight: 52)
                .padding(.horizontal, 16)
                .card()
            }
            .padding(.vertical, 8)
        }
        .scrollIndicators(.hidden)
    }

    var budgetPage: some View {
        VStack(spacing: 20) {
            pageHeader(
                "月の予算",
                message: "1 か月に使う額を決めると、\nホームで「あといくら」が分かります"
            )

            Button {
                withAnimation(.snappy) {
                    model.budget.startEditing(.total)
                }
            } label: {
                VStack(spacing: 8) {
                    Text("\(model.budget.month.month)月の予算")
                        .textFont(.caption2)
                        .tracking(3)
                        .foregroundStyle(Palette.accent)

                    Text(budgetText)
                        .displayFont(.largeTitle, weight: .bold)
                        .monospacedDigit()
                        .foregroundStyle(budgetColor)

                    Text("押して入れられます")
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .card(cornerRadius: 24)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            Text("決めなくても始められます。\nカテゴリごとの予算は、設定の「予算」から入れられます")
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)
        }
    }

    var setupPage: some View {
        ScrollView {
            VStack(spacing: 20) {
                pageHeader(
                    "ほかに決めること",
                    message: "押すと設定の画面が開きます。\nあとからでも、設定で変えられます"
                )

                setupSection("記録の準備", items: SetupItem.onboarding)
                setupSection("自分好みに", items: SetupItem.customize)
            }
            .padding(.vertical, 8)
        }
        .scrollIndicators(.hidden)
    }

    func setupSection(
        _ title: String,
        items: [SetupItem]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .textFont(.caption2)
                .tracking(3)
                .foregroundStyle(Palette.accent)
                .padding(.leading, 8)

            SetupList(items, model: model.setup) { item in
                path.append(item)
            }
            .padding(.horizontal, 16)
            .card()
        }
    }

    func pageHeader(
        _ title: String,
        message: String
    ) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .displayFont(.headline)
                .tracking(4)
                .foregroundStyle(Palette.accent)

            Text(message)
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
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
                    .font(.footnote)
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
    var budgetText: String {
        model.budget.totalAmount.map { AmountText.text($0) } ?? "なし"
    }

    var budgetColor: Color {
        model.budget.totalAmount == nil ? Palette.hint : Palette.accentStrong
    }

    var weekStartBinding: Binding<Weekday> {
        Binding {
            model.weekStart
        } set: { weekStart in
            Task {
                await model.chooseWeekStart(weekStart)
            }
        }
    }

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
