import Core
import DesignSystem
import Store
import SwiftUI

public struct OnboardingView: View {
    @State private var model: OnboardingModel

    private let onFinish: () -> Void

    public init(
        database: AppDatabase,
        today: LocalDate,
        onFinish: @escaping () -> Void
    ) {
        _model = State(
            initialValue: OnboardingModel(database: database, today: today)
        )

        self.onFinish = onFinish
    }

    public var body: some View {
        VStack(spacing: 18) {
            topBar

            ZStack {
                page
                    .id(model.page)
                    .transition(.page(forward: model.isMovingForward))
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .contentShape(.rect)
            .onPageSwipe { direction in
                turnPage(direction)
            }

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Palette.rose)
            }

            PrimaryButton(model.nextTitle) {
                Task {
                    await next()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            Rectangle()
                .fill(Palette.night)
                .ignoresSafeArea()
        }
        .budgetKeypad(model.budget)
        .preferredColorScheme(.dark)
        .sensoryFeedback(.selection, trigger: model.page)
        .task {
            await model.load()
        }
        .task(id: model.page) {
            await model.refreshPage()
        }
    }
}

private extension OnboardingView {
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

            PageDots(
                count: OnboardingModel.Page.allCases.count,
                current: model.page.rawValue
            )

            Spacer()

            Button("スキップ") {
                Task {
                    await finish()
                }
            }
            .font(.footnote)
            .foregroundStyle(Palette.mist)
            .frame(minWidth: 44, minHeight: 44)
        }
    }

    @ViewBuilder
    var page: some View {
        switch model.page {
        case .welcome: welcomePage
        case .monthStart: monthStartPage
        case .budget: budgetPage
        case .launchScreen: launchScreenPage
        }
    }

    var welcomePage: some View {
        VStack(spacing: 22) {
            VStack(spacing: 10) {
                Text("ようこそ")
                    .font(.system(size: 26, design: .serif))
                    .tracking(8)
                    .foregroundStyle(Palette.gold)

                Text("毎日の記録を、すばやく、心地よく")
                    .font(.subheadline)
                    .foregroundStyle(Palette.champagne)
            }
            .padding(.top, 36)

            Text("はじめに、次のことを決めます。どれも、あとで設定から変えられます")
                .font(.caption)
                .foregroundStyle(Palette.mist)
                .multilineTextAlignment(.center)

            VStack(spacing: 0) {
                stepRow("月と週の始まり", systemImage: "calendar")
                hairline
                stepRow("月の予算", systemImage: "chart.bar")
                hairline
                stepRow("起動時に開く画面", systemImage: "iphone")
            }
            .padding(.horizontal, 14)
            .card()
        }
    }

    var monthStartPage: some View {
        ScrollView {
            VStack(spacing: 18) {
                pageHeader(
                    "月と週の始まり",
                    message: "給料日に合わせると、給料日から次の給料日の前の日までを 1 か月として数えます"
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
                        .font(.subheadline)
                        .foregroundStyle(Palette.ink)

                    Spacer()

                    CapsulePicker(
                        selection: weekStartBinding,
                        options: Weekday.weekStartOptions
                    )
                }
                .frame(minHeight: 52)
                .padding(.horizontal, 14)
                .card()
            }
            .padding(.vertical, 8)
        }
        .scrollIndicators(.hidden)
    }

    var budgetPage: some View {
        VStack(spacing: 18) {
            pageHeader(
                "月の予算",
                message: "1 か月に使う額を決めると、ホームで「あといくら」が分かります"
            )

            Button {
                withAnimation(.snappy) {
                    model.budget.startEditing(.total)
                }
            } label: {
                VStack(spacing: 6) {
                    Text("\(model.budget.month.month)月の予算")
                        .font(.caption2)
                        .tracking(3)
                        .foregroundStyle(Palette.gold)

                    Text(budgetText)
                        .font(.system(size: 30, weight: .bold, design: .serif))
                        .monospacedDigit()
                        .foregroundStyle(budgetColor)

                    Text("押して入れられます")
                        .font(.caption2)
                        .foregroundStyle(Palette.mist)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .card(cornerRadius: 22)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            Text("決めなくても始められます。カテゴリごとの予算は、設定の「予算」から入れられます")
                .font(.caption2)
                .foregroundStyle(Palette.mist)
                .multilineTextAlignment(.center)
        }
    }

    var launchScreenPage: some View {
        VStack(spacing: 18) {
            pageHeader(
                "起動時に開く画面",
                message: "アプリを開いたときに、最初に出す画面を選びます"
            )

            ForEach(LaunchScreen.allCases, id: \.self) { screen in
                launchOption(screen)
            }
        }
    }

    var hairline: some View {
        Rectangle()
            .fill(Palette.gold.opacity(0.1))
            .frame(height: 0.5)
    }

    func pageHeader(
        _ title: String,
        message: String
    ) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 20, design: .serif))
                .tracking(4)
                .foregroundStyle(Palette.gold)

            Text(message)
                .font(.caption)
                .foregroundStyle(Palette.mist)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    func stepRow(
        _ title: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(Palette.gold)
                .frame(width: 22)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(Palette.ink)

            Spacer()
        }
        .frame(minHeight: 48)
    }

    func launchOption(_ screen: LaunchScreen) -> some View {
        let isSelected = model.launchScreen == screen
        let stroke = isSelected ? Palette.gold : Palette.gold.opacity(0.2)
        let fill = isSelected ? Palette.gold.opacity(0.1) : Color.clear
        let mark = isSelected ? "checkmark.circle.fill" : "circle"

        return Button {
            withAnimation(.snappy(duration: 0.2)) {
                model.launchScreen = screen
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: screen.systemImage)
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(Palette.gold)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(screen.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.champagne)

                    Text(screen.note)
                        .font(.caption)
                        .foregroundStyle(Palette.mist)
                }

                Spacer()

                Image(systemName: mark)
                    .font(.system(size: 18))
                    .foregroundStyle(Palette.gold)
            }
            .padding(16)
            .background(fill, in: .rect(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(stroke, lineWidth: 1)
            }
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
        model.budget.totalAmount == nil ? Palette.dusk : Palette.champagne
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
        withAnimation(.snappy) {
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
