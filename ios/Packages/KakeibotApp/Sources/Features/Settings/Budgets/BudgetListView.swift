import Core
import DesignSystem
import Store
import SwiftUI

public struct BudgetListView: View {
    @State private var model: BudgetListModel

    @Environment(\.dismiss) private var dismiss

    public init(model: BudgetListModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        content
            .errorBanner(model.errorNotice) {
                model.errorNotice.clear()
            }
            .budgetKeypad(model)
            .toolbar(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)
            .sensoryFeedback(.selection, trigger: model.budgets)
            .task {
                await model.load()
            }
    }
}

private extension BudgetListView {
    var content: some View {
        VStack(spacing: 16) {
            header

            VStack(spacing: 4) {
                Text("\(model.month.month)月（\(model.periodText)）から使う額")
                    .font(.caption)
                    .foregroundStyle(Palette.champagne)

                Text("変えた額はこの月から使い、前の月はそのまま残ります")
                    .font(.caption2)
                    .foregroundStyle(Palette.mist)

                if model.recurringExpense > 0 {
                    Label(recurringText, systemImage: "repeat")
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(Palette.gold)
                        .padding(.top, 4)
                }
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    totalCard

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            SettingsSectionTitle("カテゴリごと")

                            Spacer()

                            Text("合計 \(AmountText.text(model.categoriesTotal))")
                                .font(.caption2)
                                .monospacedDigit()
                                .foregroundStyle(Palette.mist)
                        }

                        VStack(spacing: 0) {
                            ForEach(model.categories) { category in
                                categoryRow(category)

                                if category.id != model.categories.last?.id {
                                    Rectangle()
                                        .fill(Palette.gold.opacity(0.1))
                                        .frame(height: 0.5)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .card()
                    }
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            Rectangle()
                .fill(Palette.night)
                .ignoresSafeArea()
        }
    }

    var header: some View {
        HStack {
            RingButton(systemImage: "chevron.left") {
                dismiss()
            }

            Spacer()

            Text("予算")
                .font(.system(size: 16, design: .serif))
                .tracking(4)
                .foregroundStyle(Palette.gold)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    var totalCard: some View {
        Button {
            openDrawer(.total)
        } label: {
            VStack(spacing: 6) {
                Text("月全体")
                    .font(.caption2)
                    .tracking(3)
                    .foregroundStyle(Palette.gold)

                Text(amountText(model.totalAmount))
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .monospacedDigit()
                    .foregroundStyle(amountColor(model.totalAmount))

                if let usage = model.usage(for: nil) {
                    usageLine(usage)
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                } else {
                    Text("押して変えられます")
                        .font(.caption2)
                        .foregroundStyle(Palette.mist)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .card(cornerRadius: 22)
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
            VStack(spacing: 6) {
                HStack(spacing: 12) {
                    IconImage(model.icon(for: category), size: 16)
                        .foregroundStyle(Palette.gold)
                        .frame(width: 24)

                    Text(category.name)
                        .font(.subheadline)
                        .foregroundStyle(Palette.ink)

                    Spacer()

                    Text(amountText(amount))
                        .font(.system(size: 16, design: .serif))
                        .monospacedDigit()
                        .foregroundStyle(amountColor(amount))
                }

                if let usage {
                    usageLine(usage)
                        .padding(.leading, 36)
                } else if spent > 0 {
                    Text("使った額 \(AmountText.text(spent))")
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(Palette.mist)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 36)
                }
            }
            .padding(.vertical, 10)
            .frame(minHeight: 48)
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
            .font(.caption2)
            .monospacedDigit()
            .foregroundStyle(Palette.mist)
        }
    }
}

private extension BudgetListView {
    var recurringText: String {
        let amount = AmountText.text(model.recurringExpense)
        return "この月の固定費は \(amount)。予算の目安にできます"
    }

    func amountText(_ amount: Int?) -> String {
        amount.map { AmountText.text($0) } ?? "なし"
    }

    func amountColor(_ amount: Int?) -> Color {
        amount == nil ? Palette.dusk : Palette.champagne
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
