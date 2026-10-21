import Core
import DesignSystem
import Store
import SwiftUI

public struct RecurringListView: View {
    @State private var drag = SettingsDrag<Recurring.ID>()
    @State private var model: RecurringListModel
    @State private var sheet: Sheet?
    @State private var openId: Recurring.ID?
    @State private var deleting: Recurring.ID?
    @State private var isConfirmingDelete = false
    @State private var hiddenId: Recurring.ID?
    @State private var deletion: Deletion?
    @State private var isConfirmingDeleteHidden = false
    @State private var hiddenList: SettingsScreenFlag

    public init(model: RecurringListModel) {
        _model = State(initialValue: model)
        _hiddenList = State(initialValue: model.hiddenListFlag())
    }

    public var body: some View {
        VStack(spacing: 14) {
            SettingsBackHeader("固定費")

            SettingsHint(flag: model.hintFlag(), lines: hint)

            ScrollView {
                VStack(spacing: 14) {
                    if !model.rows.isEmpty {
                        totalCard
                    }

                    board

                    if model.rows.isEmpty {
                        Text("家賃や給料などを足すと、ここに並びます")
                            .textFont(.footnote)
                            .foregroundStyle(Palette.subtext)
                            .padding(.vertical, 40)
                    }

                    if !model.hiddenRows.isEmpty {
                        hiddenSection
                    }
                }
                .padding(.vertical, 8)
                .coordinateSpace(.named(Self.space))
                .onGeometryChange(for: CGPoint.self) { proxy in
                    proxy.frame(in: .global).origin
                } action: { origin in
                    drag.origin = origin
                }
            }
            .scrollIndicators(.hidden)
            .scrollDisabled(drag.isLifting)
            .settingsAutoScroll(drag.autoScroll)
            .settingsDropZones($drag.zones, showing: drag.showZone)
            .settingsHideNotice($hiddenId, message: "止めて非表示にしました") { id in
                show(id)
            }
            .deletionNotice($deletion) { deletion in
                restore(deletion)
            }

            if drag.lift != nil {
                SettingsHideTarget(
                    zones: $drag.zones,
                    isArmed: drag.isOverHide
                )
            } else {
                AddButton("固定費を追加") {
                    sheet = .new
                }
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
                .fill(Palette.background)
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.impact(weight: .medium), trigger: drag.liftCount)
        .sensoryFeedback(.selection, trigger: model.movingOrder)
        .sensoryFeedback(.success, trigger: drag.showCount)
        .sheet(item: $sheet) { sheet in
            RecurringEditSheet(
                model: model.editModel(for: sheet.editingId)
            ) { deletion in
                self.deletion = deletion
            }
        }
        .confirmation(
            isPresented: $isConfirmingDelete,
            systemImage: "trash",
            title: "この固定費を削除しますか",
            message: "これまでに作った記録は残ります",
            keepTitle: "やめる",
            confirmTitle: "削除する"
        ) {
            if let deleting {
                delete(deleting)
            }
        }
        .confirmation(
            isPresented: $isConfirmingDeleteHidden,
            systemImage: "trash",
            title: "非表示の固定費をまとめて削除しますか",
            message: "これまでに作った記録は残ります",
            keepTitle: "やめる",
            confirmTitle: "まとめて削除する"
        ) {
            deleteHidden()
        }
        .task {
            await model.observe()
        }
    }
}

private extension RecurringListView {
    var totalCard: some View {
        HStack(spacing: 0) {
            totalColumn("今月の支出", amount: model.monthTotal.expense)

            Rectangle()
                .fill(Palette.accent.opacity(.soft))
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

    var hiddenSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SettingsHiddenTitle(
                flag: hiddenList,
                title: "非表示の固定費",
                count: model.hiddenRows.count
            ) {
                isConfirmingDeleteHidden = true
            }

            if hiddenList.isOn {
                ForEach(model.hiddenRows) { row in
                    hiddenRow(row)
                }
            }
        }
    }

    func hiddenRow(_ row: RecurringListModel.Row) -> some View {
        let lifted = drag.hiddenOffset(of: row.id)
        let isLifted = lifted != nil
        let offset = lifted ?? .zero
        let scale: CGFloat = isLifted ? 1.03 : 1
        let shadow = Palette.shadow.opacity(isLifted ? 0.5 : 0)
        let opacity: Double = isLifted ? 1 : 0.5
        let layer: Double = isLifted ? 1 : 0

        return rowCard(row, isPaused: true)
            .frame(height: Self.rowHeight)
            .opacity(opacity)
            .scaleEffect(scale)
            .shadow(color: shadow, radius: 16, y: 8)
            .offset(offset)
            .zIndex(layer)
            .onTapGesture {
                sheet = .edit(row.id)
            }
            .gesture(
                LiftGesture(in: Self.space) { location in
                    followHidden(row.id, to: location)
                } onEnd: {
                    dropHidden()
                }
            )
    }

    func totalColumn(
        _ title: String,
        amount: Int
    ) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .textFont(.caption2)
                .tracking(2)
                .foregroundStyle(Palette.accent)

            Text(AmountText.text(amount))
                .displayFont(.headline)
                .monospacedDigit()
                .foregroundStyle(Palette.accentStrong)
        }
        .frame(maxWidth: .infinity)
    }

    func movableRow(
        _ row: RecurringListModel.Row,
        in rows: [RecurringListModel.Row]
    ) -> some View {
        let isLifted = drag.isLifted(row.id)
        let index = rows.firstIndex { $0.id == row.id } ?? 0
        let center = isLifted ? drag.liftedCenter : Self.grid.center(at: index)
        let scale: CGFloat = isLifted ? 1.03 : 1
        let shadow = Palette.shadow.opacity(isLifted ? 0.5 : 0)
        let layer: Double = isLifted ? 1 : 0

        return SwipeRow(id: row.id, openId: $openId, role: .hide) {
            sheet = .edit(row.id)
        } onAction: {
            hide(row.id)
        } onDelete: {
            requestDelete(row.id)
        } content: {
            rowCard(row, isPaused: false)
        }
        .frame(height: Self.rowHeight)
        .scaleEffect(scale)
        .shadow(color: shadow, radius: 16, y: 8)
        .offset(y: center.y - Self.rowHeight / 2)
        .zIndex(layer)
        .gesture(
            LiftGesture(in: Self.space) { location in
                follow(row, at: index, to: location)
            } onEnd: {
                drop()
            }
        )
    }

    func rowCard(
        _ row: RecurringListModel.Row,
        isPaused: Bool
    ) -> some View {
        Group {
            HStack(spacing: 12) {
                IconBadge(row.icon, size: 38)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(row.title)
                            .textFont(.subheadline)
                            .foregroundStyle(Palette.text)
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        AmountText(row.amount, type: row.type)
                    }

                    Text(row.schedule)
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(1)

                    HStack(alignment: .firstTextBaseline) {
                        if let place = row.place {
                            Text(place)
                                .textFont(.caption)
                                .foregroundStyle(Palette.subtext)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 8)

                        if isPaused {
                            Label("止めています", systemImage: "pause.circle")
                                .textFont(.caption2)
                                .foregroundStyle(Palette.amber)
                        } else {
                            Text(Self.nextText(row))
                                .textFont(.caption2)
                                .foregroundStyle(Palette.subtext)
                        }
                    }
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
    enum Sheet: Identifiable {
        case new
        case edit(Recurring.ID)
    }

    static let rowHeight: CGFloat = 84
    nonisolated static let space = "RecurringList"
    static let grid = SettingsBoardGrid(
        columns: 1,
        itemHeight: rowHeight,
        spacing: 10
    )

    static let purpose = SettingsHint.Line(
        "calendar.badge.clock",
        "決まった日に、記録をひとりでに入れます"
    )

    var hint: [SettingsHint.Line] {
        if model.rows.isEmpty {
            [Self.purpose]
        } else {
            [
                Self.purpose,
                .move,
                .init("pause.circle", "下の枠に置くと止められます"),
                .init("hand.point.left", "横に払うと、止めると削除のボタンが出ます")
            ]
        }
    }

    func boardHeight(count: Int) -> CGFloat {
        Self.grid.height(slots: count)
    }

    func follow(
        _ row: RecurringListModel.Row,
        at index: Int,
        to location: CGPoint
    ) {
        let start = Self.grid.center(at: index)

        let center = drag.follow(row.id, from: start, to: location) { next in
            follow(row, at: index, to: next)
        }

        guard let center else {
            return
        }

        let target = Self.grid.index(at: center, count: model.rows.count)

        withAnimation(.snappy) {
            model.move(row.id, to: target)
        }
    }

    func drop() {
        switch drag.drop() {
        case let .hide(id):
            hide(id)
        case .move:
            Task {
                await model.finishMoving()
            }
        case nil:
            break
        }
    }

    func hide(_ id: Recurring.ID) {
        Task {
            if await model.hide(id) {
                hiddenId = id
            }
        }
    }

    func requestDelete(_ id: Recurring.ID) {
        deleting = id
        isConfirmingDelete = true
    }

    func delete(_ id: Recurring.ID) {
        Task {
            deletion = await model.delete(id)
        }
    }

    func deleteHidden() {
        Task {
            deletion = await model.deleteHidden()
        }
    }

    func restore(_ deletion: Deletion) {
        Task {
            await model.restore(deletion)
        }
    }

    func show(_ id: Recurring.ID) {
        Task {
            await model.show(id)
        }
    }

    func followHidden(
        _ id: Recurring.ID,
        to location: CGPoint
    ) {
        drag.followHidden(id, to: location)
    }

    func dropHidden() {
        guard let id = drag.dropHidden() else {
            return
        }

        show(id)
    }

    static func nextText(_ row: RecurringListModel.Row) -> String {
        guard let date = row.next else {
            return "終わりました"
        }

        let next = "次は \(date.month)/\(date.day)"
        return [row.closing, next].compactMap(\.self).joined(separator: "・")
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
