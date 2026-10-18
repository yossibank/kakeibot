import Core
import DesignSystem
import Store
import SwiftUI

public struct RecurringListView: View {
    @State private var model: RecurringListModel
    @State private var sheet: Sheet?
    @State private var lift: Lift?
    @State private var liftCount = 0
    @State private var openId: Recurring.ID?
    @State private var deleting: Recurring.ID?

    @Environment(\.dismiss) private var dismiss

    public init(model: RecurringListModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: 14) {
            header

            Text(hint)
                .font(.caption)
                .foregroundStyle(Palette.mist)
                .multilineTextAlignment(.center)

            ScrollView {
                VStack(spacing: 14) {
                    if !model.rows.isEmpty {
                        totalCard
                    }

                    board
                        .coordinateSpace(.named(Self.space))

                    if model.rows.isEmpty {
                        Text("家賃や給料などを足すと、ここに並びます")
                            .font(.footnote)
                            .foregroundStyle(Palette.mist)
                            .padding(.vertical, 40)
                    }
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
            .scrollDisabled(lift != nil)

            AddButton("固定費を追加") {
                sheet = .new
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .background {
            Rectangle()
                .fill(Palette.night)
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
        .sensoryFeedback(.impact(weight: .medium), trigger: liftCount)
        .sensoryFeedback(.selection, trigger: model.movingOrder)
        .confirmation(
            isPresented: deleteBinding,
            systemImage: "trash",
            title: "この固定費を消しますか",
            message: "これまでに作った記録は残ります",
            keepTitle: "やめる",
            confirmTitle: "消す"
        ) {
            if let deleting {
                Task {
                    await model.delete(deleting)
                }
            }
        }
        .sheet(item: $sheet) { sheet in
            RecurringEditSheet(model: model.editModel(for: sheet.editingId))
        }
        .task {
            await model.observe()
        }
    }
}

private extension RecurringListView {
    var header: some View {
        HStack {
            RingButton(systemImage: "chevron.left") {
                dismiss()
            }

            Spacer()

            Text("固定費")
                .font(.system(size: 16, design: .serif))
                .tracking(4)
                .foregroundStyle(Palette.gold)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    var totalCard: some View {
        HStack(spacing: 0) {
            totalColumn("今月の支出", amount: model.monthTotal.expense)

            Rectangle()
                .fill(Palette.gold.opacity(0.18))
                .frame(width: 1, height: 34)

            totalColumn("今月の収入", amount: model.monthTotal.income)
        }
        .padding(.vertical, 14)
        .card()
    }

    var board: some View {
        let rows = model.rows

        return ZStack(alignment: .top) {
            ForEach(rows) { row in
                movableRow(row, in: rows)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: boardHeight(count: rows.count), alignment: .top)
    }

    func totalColumn(
        _ title: String,
        amount: Int
    ) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .tracking(2)
                .foregroundStyle(Palette.gold)

            Text(AmountText.text(amount))
                .font(.system(size: 20, design: .serif))
                .monospacedDigit()
                .foregroundStyle(Palette.champagne)
        }
        .frame(maxWidth: .infinity)
    }

    func movableRow(
        _ row: RecurringListModel.Row,
        in rows: [RecurringListModel.Row]
    ) -> some View {
        let isLifted = lift?.id == row.id
        let index = rows.firstIndex { $0.id == row.id } ?? 0
        let y = isLifted ? liftedCenterY : centerY(at: index)
        let scale: CGFloat = isLifted ? 1.03 : 1
        let shadow = Color.black.opacity(isLifted ? 0.5 : 0)
        let layer: Double = isLifted ? 1 : 0

        return SwipeRow(id: row.id, openId: $openId) {
            sheet = .edit(row.id)
        } onAction: {
            deleting = row.id
        } content: {
            rowCard(row)
        }
        .frame(height: Self.rowHeight)
        .scaleEffect(scale)
        .shadow(color: shadow, radius: 16, y: 8)
        .offset(y: y - Self.rowHeight / 2)
        .zIndex(layer)
        .gesture(
            LiftGesture(in: Self.space) { location in
                follow(row, at: index, to: location)
            } onEnd: {
                drop()
            }
        )
    }

    func rowCard(_ row: RecurringListModel.Row) -> some View {
        Group {
            HStack(spacing: 12) {
                IconBadge(row.icon, size: 38)

                VStack(alignment: .leading, spacing: 3) {
                    Text(row.title)
                        .font(.subheadline)
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)

                    Text(row.detail)
                        .font(.caption)
                        .foregroundStyle(Palette.mist)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 3) {
                    AmountText(row.amount, type: row.type)

                    Text(Self.nextText(row.next))
                        .font(.caption2)
                        .foregroundStyle(Palette.mist)
                }
            }
            .padding(.horizontal, 14)
            .frame(maxHeight: .infinity)
            .contentShape(.rect)
        }
        .card()
    }
}

private extension RecurringListView {
    struct Lift {
        let id: Recurring.ID
        var location: CGFloat
        var grab: CGFloat?
    }

    enum Sheet: Identifiable {
        case new
        case edit(Recurring.ID)
    }

    static let rowHeight: CGFloat = 64
    static let spacing: CGFloat = 10
    nonisolated static let space = "RecurringBoard"

    var hint: String {
        if model.rows.count > 1 {
            "決まった日に、記録をひとりでに入れます。長押しで動かせます"
        } else {
            "決まった日に、記録をひとりでに入れます"
        }
    }

    var deleteBinding: Binding<Bool> {
        Binding {
            deleting != nil
        } set: { isPresented in
            if !isPresented {
                deleting = nil
            }
        }
    }

    var liftedCenterY: CGFloat {
        guard let lift else {
            return 0
        }

        return lift.location + (lift.grab ?? 0)
    }

    func boardHeight(count: Int) -> CGFloat {
        let gaps = Self.spacing * CGFloat(max(count - 1, 0))
        return Self.rowHeight * CGFloat(count) + gaps
    }

    func centerY(at index: Int) -> CGFloat {
        (Self.rowHeight + Self.spacing) * CGFloat(index) + Self.rowHeight / 2
    }

    func index(at y: CGFloat) -> Int {
        let step = Self.rowHeight + Self.spacing
        let index = max(Int(y / step), 0)
        return min(index, model.rows.count - 1)
    }

    func follow(
        _ row: RecurringListModel.Row,
        at index: Int,
        to location: CGPoint
    ) {
        if lift == nil {
            withAnimation(.snappy(duration: 0.2)) {
                lift = Lift(id: row.id, location: centerY(at: index))
            }

            liftCount += 1
        }

        guard var current = lift else {
            return
        }

        if current.grab == nil {
            current.grab = current.location - location.y
        }

        current.location = location.y
        lift = current

        let target = self.index(at: liftedCenterY)

        withAnimation(.snappy) {
            model.move(row.id, to: target)
        }
    }

    func drop() {
        guard lift != nil else {
            return
        }

        withAnimation(.snappy) {
            lift = nil
        }

        Task {
            await model.finishMoving()
        }
    }

    static func nextText(_ date: LocalDate?) -> String {
        guard let date else {
            return "終わりました"
        }

        return "次は \(date.month)/\(date.day)"
    }
}

private extension RecurringListView.Sheet {
    var id: String {
        switch self {
        case .new: "new"
        case let .edit(id): id.description
        }
    }

    var editingId: Recurring.ID? {
        switch self {
        case .new: nil
        case let .edit(id): id
        }
    }
}
