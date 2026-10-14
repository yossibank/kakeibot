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
                recordedToast(recorded)
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

                Text(templateHint)
                    .font(.caption2)
                    .foregroundStyle(Palette.mist)
            }

            LazyVGrid(columns: Self.templateColumns, spacing: 8) {
                ForEach(model.templates) { template in
                    templateButton(template)
                }

                Button(action: onAddTemplate) {
                    Label("追加", systemImage: "plus")
                        .font(.footnote)
                        .foregroundStyle(Palette.gold)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
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
        let amount = template.amount.map { AmountText.text($0) } ?? "金額を入れる"
        let amountColor = template.amount == nil
            ? Palette.mist
            : Palette.champagne

        return Button {
            use(template)
        } label: {
            HStack(spacing: 10) {
                IconImage(model.icon(for: template), size: 17)
                    .foregroundStyle(Palette.gold)

                VStack(alignment: .leading, spacing: 1) {
                    Text(template.name)
                        .font(.footnote)
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)

                    Text(amount)
                        .font(.system(size: 12, design: .serif))
                        .foregroundStyle(amountColor)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Palette.gold.opacity(0.04), in: .rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Palette.gold.opacity(0.22), lineWidth: 1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    func recordedToast(_ recorded: HomeModel.Recorded) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.gold)

            Text(recorded.message)
                .font(.footnote)
                .foregroundStyle(Palette.ink)
                .lineLimit(1)

            Spacer(minLength: 8)

            Button {
                Task {
                    await model.undoRecorded()
                }
            } label: {
                Text("取り消す")
                    .font(.caption)
                    .foregroundStyle(Palette.gold)
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .overlay {
                        Capsule()
                            .stroke(Palette.gold.opacity(0.45), lineWidth: 1)
                    }
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 18)
        .padding(.trailing, 8)
        .frame(height: 50)
        .background(Palette.drawer, in: Capsule())
        .overlay {
            Capsule()
                .stroke(Palette.gold.opacity(0.55), lineWidth: 0.8)
        }
        .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
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
