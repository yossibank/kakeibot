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
    @State private var boardOrigin: CGPoint = .zero
    @State private var listOrigin: CGPoint = .zero
    @State private var zones = SettingsDropZones()
    @State private var autoScroll = SettingsAutoScroll()
    @State private var hideHover = SettingsHideHover()
    @State private var hiddenId: Recurring.ID?
    @State private var hiddenList: SettingsScreenFlag
    @State private var hiddenLift: SettingsHiddenLift<Recurring.ID>?
    @State private var isOverShowZone = false
    @State private var showCount = 0

    @Environment(\.dismiss) private var dismiss

    public init(model: RecurringListModel) {
        _model = State(initialValue: model)
        _hiddenList = State(initialValue: model.hiddenListFlag())
    }

    public var body: some View {
        VStack(spacing: 14) {
            header

            SettingsHint(flag: model.hintFlag(), lines: hint)

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
                            .foregroundStyle(Palette.subtext)
                            .padding(.vertical, 40)
                    }

                    if !model.hiddenRows.isEmpty {
                        hiddenSection
                    }
                }
                .padding(.vertical, 8)
                .coordinateSpace(.named(Self.listSpace))
                .onGeometryChange(for: CGPoint.self) { proxy in
                    proxy.frame(in: .global).origin
                } action: { origin in
                    listOrigin = origin
                }
            }
            .scrollIndicators(.hidden)
            .scrollDisabled(lift != nil || hiddenLift != nil)
            .settingsAutoScroll(autoScroll)
            .settingsDropZones(
                $zones,
                showing: hiddenLift == nil ? nil : isOverShowZone
            )
            .settingsHideNotice($hiddenId, message: "止めて非表示にしました") { id in
                show(id)
            }

            if lift != nil {
                SettingsHideTarget(zones: $zones, state: hideHover.state)
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
        .sensoryFeedback(.impact(weight: .medium), trigger: liftCount)
        .sensoryFeedback(.selection, trigger: model.movingOrder)
        .sensoryFeedback(.success, trigger: showCount)
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
                .displayFont(.body)
                .tracking(4)
                .foregroundStyle(Palette.accent)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
    }

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
        .onGeometryChange(for: CGPoint.self) { proxy in
            proxy.frame(in: .global).origin
        } action: { origin in
            boardOrigin = origin
        }
    }

    var hiddenSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SettingsHiddenTitle(
                flag: hiddenList,
                title: "非表示の固定費",
                count: model.hiddenRows.count
            )

            if hiddenList.isOn {
                ForEach(model.hiddenRows) { row in
                    hiddenRow(row)
                }
            }
        }
    }

    func hiddenRow(_ row: RecurringListModel.Row) -> some View {
        let isLifted = hiddenLift?.id == row.id
        let offset = isLifted ? hiddenLift?.offset ?? .zero : .zero
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
                LiftGesture(in: Self.listSpace) { location in
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
                .font(.caption2)
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
        let isLifted = lift?.id == row.id
        let index = rows.firstIndex { $0.id == row.id } ?? 0
        let y = isLifted ? liftedCenterY : centerY(at: index)
        let scale: CGFloat = isLifted ? 1.03 : 1
        let shadow = Palette.shadow.opacity(isLifted ? 0.5 : 0)
        let layer: Double = isLifted ? 1 : 0

        return SwipeRow(id: row.id, openId: $openId, role: .hide) {
            sheet = .edit(row.id)
        } onAction: {
            hide(row.id)
        } content: {
            rowCard(row, isPaused: false)
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

    func rowCard(
        _ row: RecurringListModel.Row,
        isPaused: Bool
    ) -> some View {
        Group {
            HStack(spacing: 12) {
                IconBadge(row.icon, size: 38)

                VStack(alignment: .leading, spacing: 3) {
                    Text(row.title)
                        .font(.subheadline)
                        .foregroundStyle(Palette.text)
                        .lineLimit(1)

                    Text(row.detail)
                        .font(.caption)
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 3) {
                    AmountText(row.amount, type: row.type)

                    if isPaused {
                        Label("止めています", systemImage: "pause.circle")
                            .font(.caption2)
                            .foregroundStyle(Palette.amber)
                    } else {
                        Text(Self.nextText(row.next))
                            .font(.caption2)
                            .foregroundStyle(Palette.subtext)
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
    nonisolated static let listSpace = "RecurringList"
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
                .init("pause.circle", "下の枠で少し待つと止められます"),
                .init("hand.point.left", "横に払っても止められます")
            ]
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

        let isInside = zones.isOverHide(location, from: boardOrigin)

        hideHover.update(isInside: isInside)

        autoScroll.follow(
            y: location.y + boardOrigin.y,
            bottom: zones.hide.isEmpty ? nil : zones.hide.minY
        ) { delta in
            let shifted = CGPoint(x: location.x, y: location.y + delta)
            follow(row, at: index, to: shifted)
        }

        guard !hideHover.isInside else {
            return
        }

        let target = self.index(at: liftedCenterY)

        withAnimation(.snappy) {
            model.move(row.id, to: target)
        }
    }

    func drop() {
        autoScroll.stop()

        guard let lift else {
            return
        }

        if hideHover.isArmed {
            let id = lift.id

            withAnimation(.snappy) {
                self.lift = nil
                hideHover.reset()
            }

            hide(id)

            return
        }

        hideHover.reset()

        withAnimation(.snappy) {
            self.lift = nil
        }

        Task {
            await model.finishMoving()
        }
    }

    func hide(_ id: Recurring.ID) {
        Task {
            if await model.hide(id) {
                hiddenId = id
            }
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
        if hiddenLift == nil {
            withAnimation(.snappy(duration: 0.2)) {
                hiddenLift = SettingsHiddenLift(
                    id: id,
                    start: location,
                    location: location
                )
            }

            liftCount += 1
        }

        hiddenLift?.location = location
        isOverShowZone = zones.isOverShow(location, from: listOrigin)
    }

    func dropHidden() {
        guard let hiddenLift else {
            return
        }

        let isShowing = isOverShowZone

        withAnimation(.snappy) {
            self.hiddenLift = nil
            isOverShowZone = false
        }

        guard isShowing else {
            return
        }

        showCount += 1

        Task {
            await model.show(hiddenLift.id)
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
