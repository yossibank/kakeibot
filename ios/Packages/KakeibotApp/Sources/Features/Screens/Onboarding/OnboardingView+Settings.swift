import Core
import DesignSystem
import SwiftUI

extension OnboardingView {
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
                        .editBadge()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .card()
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
}

private extension OnboardingView {
    func setupSection(
        _ title: String,
        items: [SetupItem]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title)
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
}
