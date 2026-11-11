import Core
import DesignSystem
import Store
import SwiftUI

public struct BudgetListView: View {
    @State private var model: BudgetListModel
    @State private var hintFlag: SettingsScreenFlag
    @State private var cleared: BudgetListModel.Cleared?
    @State private var resetFrom: YearMonth?

    public init(model: BudgetListModel) {
        let hintFlag = model.hintFlag()

        _model = State(initialValue: model)
        _hintFlag = State(initialValue: hintFlag)
    }

    public var body: some View {
        content
            .errorBanner(model.errorNotice) {
                model.errorNotice.clear()
            }
            .budgetKeypad(model, cleared: $cleared)
            .toolbar(.hidden, for: .navigationBar)
            .haptic(.selection, trigger: model.budgets)
            .task {
                await model.load()
            }
    }
}

private extension BudgetListView {
    var content: some View {
        VStack(spacing: SettingsSpacing.header) {
            SettingsBackHeader("予算", hint: hintFlag)

            SettingsIntroCard(
                systemImage: "chart.bar",
                headline: ("月に使う額を", "カテゴリ別に決めます"),
                notes: [
                    .init("calendar", "変えた額はこの月から使います"),
                    .init("clock.arrow.circlepath", "前の月の額はそのまま残ります")
                ],
                flag: hintFlag
            )

            ScrollView {
                VStack(alignment: .leading, spacing: SettingsSpacing.section) {
                    totalCard

                    SettingsSwitch(
                        title: "残りを繰り越す",
                        detail: "使いすぎた分は、次の月の予算から引きます",
                        systemImage: "arrow.turn.down.right",
                        isOn: model.isCarryoverOn
                    ) { isOn in
                        await model.setCarryover(isOn)
                    }

                    if !budgeted.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                SettingsSectionTitle("カテゴリごと")

                                Spacer()

                                Text("合計 \(AmountText.text(model.categoriesTotal))")
                                    .textFont(.caption2)
                                    .monospacedDigit()
                                    .foregroundStyle(Palette.subtext)
                                    .padding(.trailing, 8)
                            }

                            rowsCard(budgeted, row: categoryRow)
                        }
                    }

                    if !unbudgeted.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                SettingsSectionTitle("予算なし")

                                Spacer()

                                Text("\(unbudgeted.count) カテゴリ")
                                    .textFont(.caption2)
                                    .monospacedDigit()
                                    .foregroundStyle(Palette.subtext)
                                    .padding(.trailing, 8)
                            }

                            rowsCard(unbudgeted, row: plainRow)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
            .settingsHideNotice(
                $cleared,
                message: clearedMessage,
                systemImage: "chart.bar"
            ) { cleared in
                Task {
                    await model.restore(cleared)
                }
            }
            .settingsHideNotice(
                $resetFrom,
                message: "繰越を 0 に戻しました",
                systemImage: "arrow.counterclockwise"
            ) { start in
                Task {
                    await model.restoreCarryover(from: start)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, SettingsSpacing.top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            Backdrop()
                .ignoresSafeArea()
        }
    }

    var totalCard: some View {
        Button {
            openDrawer(.total)
        } label: {
            VStack(spacing: 8) {
                VStack(spacing: 4) {
                    Text("月全体")
                        .textFont(.caption2)
                        .tracking(3)
                        .foregroundStyle(Palette.accent)

                    Text(periodText)
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                amountValue(model.totalAmount, size: .largeTitle, weight: .bold)
                    .editBadge()

                if model.isCarryoverOn,
                   let usage = model.usage(for: nil) {
                    HStack(spacing: 8) {
                        Text(usage.carryoverText)
                            .textFont(.caption)
                            .monospacedDigit()
                            .foregroundStyle(Palette.subtext)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        if usage.carryover != 0 {
                            Button("0 に戻す") {
                                Task {
                                    resetFrom = await model.resetCarryover()
                                }
                            }
                            .textFont(.caption2, weight: .semibold)
                            .foregroundStyle(Palette.accentStrong)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Palette.panel, in: .capsule)
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                if let usage = model.usage(for: nil) {
                    usageLine(usage)
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                }

                if model.recurringExpense > 0 {
                    Label(recurringText, systemImage: "repeat")
                        .textFont(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(Palette.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .card()
            .contentShape(.rect)
            .animation(.snappy, value: model.carryoverFrom)
        }
        .buttonStyle(.plain)
    }

    func categoryRow(_ category: EntryCategory) -> some View {
        let amount = model.amount(for: category.id)
        let usage = model.usage(for: category.id)
        let spent = model.spent(for: category.id)

        return Button {
            openDrawer(.category(category))
        } label: {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    IconBadge(model.icon(for: category), size: 28)

                    Text(category.name)
                        .textFont(.subheadline)
                        .foregroundStyle(Palette.text)

                    Spacer()

                    amountValue(amount, size: .body)

                    EditBadge(size: 16)
                }

                if let usage {
                    usageLine(usage)
                        .padding(.leading, 40)
                } else if spent > 0 {
                    Text("使った額 \(AmountText.text(spent))")
                        .textFont(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(Palette.subtext)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 40)
                }
            }
            .padding(.vertical, 12)
            .frame(minHeight: 52)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    func plainRow(_ category: EntryCategory) -> some View {
        let spent = model.spent(for: category.id)

        return Button {
            openDrawer(.category(category))
        } label: {
            HStack(spacing: 12) {
                IconBadge(model.icon(for: category), size: 28)

                Text(category.name)
                    .textFont(.footnote)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)

                Spacer(minLength: 8)

                if spent > 0 {
                    Text("使った額 \(AmountText.text(spent))")
                        .textFont(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(1)
                        .layoutPriority(1)
                }

                EditBadge(size: 16)
            }
            .padding(.vertical, 8)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    func rowsCard(
        _ categories: [EntryCategory],
        row: @escaping (EntryCategory) -> some View
    ) -> some View {
        VStack(spacing: 0) {
            ForEach(categories) { category in
                row(category)

                if category.id != categories.last?.id {
                    Hairline()
                }
            }
        }
        .padding(.horizontal, 16)
        .card()
    }

    func usageLine(_ usage: BudgetUsage) -> some View {
        VStack(spacing: 4) {
            BudgetUsageBar(usage)

            HStack {
                Text("使った額 \(AmountText.text(usage.spent))")

                Spacer()

                Text(usage.remainingText)
                    .foregroundStyle(usage.tint)
                    .contentTransition(.numericText())
            }
            .textFont(.caption2)
            .monospacedDigit()
            .foregroundStyle(Palette.subtext)
        }
    }

    @ViewBuilder
    func amountValue(
        _ amount: Int?,
        size: FontSize,
        weight: Font.Weight = .regular
    ) -> some View {
        if let amount {
            AmountText(amount, font: .size(size, weight: weight), color: Palette.accentStrong)
        } else {
            Text("なし")
                .displayFont(size, weight: weight)
                .foregroundStyle(Palette.hint)
        }
    }
}

private extension BudgetListView {
    var budgeted: [EntryCategory] {
        model.categories.filter { model.amount(for: $0.id) != nil }
    }

    var unbudgeted: [EntryCategory] {
        let rest = model.categories.filter { model.amount(for: $0.id) == nil }
        let order = rest.enumerated().sorted { lhs, rhs in
            let spent = (model.spent(for: lhs.element.id), model.spent(for: rhs.element.id))
            return spent.0 == spent.1 ? lhs.offset < rhs.offset : spent.0 > spent.1
        }

        return order.map(\.element)
    }

    var periodText: String {
        "\(model.month.month)月（\(model.periodText)）から使う額"
    }

    var recurringText: String {
        "この月の固定費は \(AmountText.text(model.recurringExpense))。予算の目安にできます"
    }

    var clearedMessage: String {
        cleared.map { "\($0.target.title)をなくしました" } ?? ""
    }

    func openDrawer(_ target: BudgetListModel.Target) {
        withAnimation(.snappy) {
            model.startEditing(target)
        }
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())

        NavigationStack {
            BudgetListView(
                model: BudgetListModel(
                    database: database,
                    today: LocalDate(Date(), in: .current)
                )
            )
        }
    }
}
