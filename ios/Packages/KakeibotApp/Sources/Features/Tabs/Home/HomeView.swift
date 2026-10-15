import Core
import DesignSystem
import SwiftUI

struct HomeView: View {
    @Bindable var model: HomeModel

    let onOpenEntry: (Entry.ID) -> Void
    let onShowRecords: () -> Void
    let onOpenSettings: () -> Void
    let onOpenTemplate: (EntryTemplate) -> Void
    let onAddTemplate: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header
                dialCard
                templateCard
                recentCard

                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Palette.rose)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background {
            Rectangle()
                .fill(Palette.night)
                .ignoresSafeArea()
        }
        .overlay(alignment: .bottom) {
            if let recorded = model.recorded {
                NoticeBanner(
                    recorded.message,
                    systemImage: "checkmark",
                    actionTitle: "取り消す"
                ) {
                    Task {
                        await model.undoRecorded()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: model.recorded)
        .sensoryFeedback(.success, trigger: model.recorded) { _, new in
            new != nil
        }
        .task(id: model.recorded) {
            guard model.recorded != nil else {
                return
            }

            guard await (try? Task.sleep(for: .seconds(4))) != nil else {
                return
            }

            model.clearRecorded()
        }
    }
}

private extension HomeView {
    var header: some View {
        HStack {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(model.month.month)月")
                    .font(.system(size: 15, design: .serif))
                    .tracking(3)
                    .foregroundStyle(Palette.gold)

                Text(model.monthRangeText)
                    .font(.caption)
                    .foregroundStyle(Palette.mist)
            }

            Spacer()

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 17, weight: .light))
                    .foregroundStyle(Palette.gold)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Circle()
                            .stroke(Palette.gold.opacity(0.28), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
        }
    }

    var dialCard: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .bottom) {
                HalfDial()

                VStack(spacing: 2) {
                    Text("今月の支出")
                        .font(.system(size: 11))
                        .tracking(4)
                        .foregroundStyle(Palette.gold)

                    Text(AmountText.text(model.monthExpense))
                        .font(.system(size: 40, weight: .bold, design: .serif))
                        .monospacedDigit()
                        .foregroundStyle(Palette.champagne)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
            .frame(maxWidth: 290)

            HStack(spacing: 0) {
                stat("今日", amount: model.todayExpense, color: Palette.champagne)
                divider
                stat("昨日", amount: model.yesterdayExpense, color: Palette.ink)
                divider
                stat("今月の収入", amount: model.monthIncome, color: Palette.gold)
            }
            .padding(.top, 12)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Palette.gold.opacity(0.18))
                    .frame(height: 1)
            }
        }
        .padding(16)
        .padding(.top, 4)
        .card(cornerRadius: 24)
    }

    var templateCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionTitle("テンプレート")

                Spacer()

                CapsulePicker(
                    selection: $model.templateType,
                    options: Self.typeOptions
                )
            }

            Text(templateHint)
                .font(.caption2)
                .foregroundStyle(Palette.mist)

            LazyVGrid(columns: Self.templateColumns, spacing: 10) {
                ForEach(model.templates) { template in
                    templateButton(template)
                }

                Button(action: onAddTemplate) {
                    Label("追加", systemImage: "plus")
                        .font(.footnote)
                        .foregroundStyle(Palette.gold)
                        .frame(maxWidth: .infinity)
                        .frame(height: TemplateCardSize.regular.height)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    Palette.gold.opacity(0.45),
                                    style: Self.dash
                                )
                        }
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .card()
    }

    var recentCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                SectionTitle("最近の記録")

                Spacer()

                Button("すべて", action: onShowRecords)
                    .font(.caption)
                    .foregroundStyle(Palette.gold)
                    .frame(minHeight: 44)
            }

            if model.recentRows.isEmpty {
                Text("まだ記録がありません。右下の ＋ から記録する")
                    .font(.footnote)
                    .foregroundStyle(Palette.mist)
                    .padding(.vertical, 16)
            } else {
                ForEach(model.recentRows) { row in
                    Button {
                        onOpenEntry(row.id)
                    } label: {
                        EntryRow(
                            icon: row.icon,
                            title: row.title,
                            detail: row.detail,
                            amount: row.amount,
                            type: row.type
                        )
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(Palette.gold.opacity(0.1))
                            .frame(height: 1)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
        .card()
    }

    func templateButton(_ template: EntryTemplate) -> some View {
        Button {
            use(template)
        } label: {
            TemplateCard(
                icon: model.icon(for: template),
                name: template.name,
                detail: model.detail(for: template),
                amount: template.amount
            )
        }
        .buttonStyle(.plain)
    }

    var divider: some View {
        Rectangle()
            .fill(Palette.gold.opacity(0.18))
            .frame(width: 1, height: 32)
    }

    func stat(
        _ title: String,
        amount: Int,
        color: Color
    ) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Palette.mist)

            Text(AmountText.text(amount))
                .font(.system(size: 16, design: .serif))
                .monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}

private extension HomeView {
    static let dash = StrokeStyle(lineWidth: 1, dash: [4, 3])

    static let typeOptions: [CapsulePicker<Entry.Kind>.Option] = [
        .init("支出", value: .expense),
        .init("収入", value: .income)
    ]

    static let templateColumns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 2
    )

    var templateHint: String {
        model.templates.isEmpty ? "よく使う入力を 1 回で" : "押すとすぐ記録"
    }

    func use(_ template: EntryTemplate) {
        guard template.amount != nil else {
            onOpenTemplate(template)
            return
        }

        Task {
            await model.record(template)
        }
    }
}
