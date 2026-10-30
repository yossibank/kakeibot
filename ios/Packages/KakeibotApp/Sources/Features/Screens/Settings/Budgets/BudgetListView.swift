import Core
import DesignSystem
import Store
import SwiftUI

public struct BudgetListView: View {
    @State private var model: BudgetListModel
    @State private var hintFlag: SettingsScreenFlag

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
            .budgetKeypad(model)
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

                        VStack(spacing: 0) {
                            ForEach(model.categories) { category in
                                categoryRow(category)

                                if category.id != model.categories.last?.id {
                                    Hairline()
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .card()
                    }
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
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

                Text(amountText(model.totalAmount))
                    .displayFont(.largeTitle, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(amountColor(model.totalAmount))
                    .editBadge()

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
                    IconImage(model.icon(for: category), size: 16)
                        .foregroundStyle(Palette.accent)
                        .frame(width: 24)

                    Text(category.name)
                        .textFont(.subheadline)
                        .foregroundStyle(Palette.text)

                    Spacer()

                    Text(amountText(amount))
                        .displayFont(.body)
                        .monospacedDigit()
                        .foregroundStyle(amountColor(amount))

                    EditBadge(size: 16)
                }

                if let usage {
                    usageLine(usage)
                        .padding(.leading, 36)
                } else if spent > 0 {
                    Text("使った額 \(AmountText.text(spent))")
                        .textFont(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(Palette.subtext)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 36)
                }
            }
            .padding(.vertical, 12)
            .frame(minHeight: 52)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    func usageLine(_ usage: BudgetUsage) -> some View {
        VStack(spacing: 4) {
            UsageBar(usage)

            HStack {
                Text("使った額 \(AmountText.text(usage.spent))")

                Spacer()

                Text(usage.remainingText)
                    .foregroundStyle(usage.tint)
            }
            .textFont(.caption2)
            .monospacedDigit()
            .foregroundStyle(Palette.subtext)
        }
    }
}

private extension BudgetListView {
    var periodText: String {
        "\(model.month.month)月（\(model.periodText)）から使う額"
    }

    var recurringText: String {
        "この月の固定費は \(AmountText.text(model.recurringExpense))。予算の目安にできます"
    }

    func amountText(_ amount: Int?) -> String {
        amount.map { AmountText.text($0) } ?? "なし"
    }

    func amountColor(_ amount: Int?) -> Color {
        amount == nil ? Palette.hint : Palette.accentStrong
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
