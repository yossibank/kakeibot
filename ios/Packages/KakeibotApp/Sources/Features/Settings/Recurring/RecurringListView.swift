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
    @State private var boardFrame: CGRect = .zero
    @State private var listOrigin: CGPoint = .zero
    @State private var zones = SettingsDropZones()
    @State private var autoScroll = SettingsAutoScroll()
    @State private var isOverHideZone = false
    @State private var hiddenLift: SettingsHiddenLift<Recurring.ID>?
    @State private var isOverShowZone = false
    @State private var showCount = 0
    @State private var isHiddenOpen = false
    @State private var hiddenFrames: [Recurring.ID: CGRect] = [:]

    @Environment(\.dismiss) private var dismiss

    public init(model: RecurringListModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: 14) {
            header

            SettingsHint(model: model.hintModel(), lines: hint)

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
                hiding: lift == nil ? nil : isOverHideZone,
                showing: hiddenLift == nil ? nil : isOverShowZone
            )
            .settingsLiftPreview(
                at: liftPreviewCenter,
                in: autoScroll.viewport
            ) {
                liftPreview
            }

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
        .sensoryFeedback(.success, trigger: showCount)
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
                .font(.serif(.body))
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
                .fill(Palette.gold.opacity(.soft))
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
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            boardFrame = frame
        }
    }

    var hiddenSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SettingsHiddenTitle(
                isOpen: $isHiddenOpen,
                title: "非表示の固定費",
                count: model.hiddenRows.count
            )

            if isHiddenOpen {
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
        let opacity: Double = isLifted ? 1 : 0.5
        let layer: Double = isLifted ? 1 : 0

        return rowCard(row, isPaused: true)
            .frame(height: Self.rowHeight)
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global)
            } action: { frame in
                hiddenFrames[row.id] = frame
            }
            .opacity(opacity)
            .scaleEffect(scale)
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
                .foregroundStyle(Palette.gold)

            Text(AmountText.text(amount))
                .font(.serif(.headline))
                .monospacedDigit()
                .foregroundStyle(Palette.champagne)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    var liftPreview: some View {
        if let lift,
           let row = model.rows.first(where: { $0.id == lift.id }) {
            rowCard(row, isPaused: false)
                .frame(width: boardFrame.width, height: Self.rowHeight)
                .scaleEffect(1.03)
        } else if let hiddenLift,
                  let row = model.hiddenRows
                  .first(where: { $0.id == hiddenLift.id }),
                  let frame = hiddenFrames[hiddenLift.id] {
            rowCard(row, isPaused: true)
                .frame(width: frame.width, height: Self.rowHeight)
                .scaleEffect(1.03)
        }
    }

    func movableRow(
        _ row: RecurringListModel.Row,
        in rows: [RecurringListModel.Row]
    ) -> some View {
        let isLifted = lift?.id == row.id
        let index = rows.firstIndex { $0.id == row.id } ?? 0
        let y = isLifted ? liftedCenterY : centerY(at: index)
        let scale: CGFloat = isLifted ? 1.03 : 1
        let layer: Double = isLifted ? 1 : 0

        return SwipeRow(id: row.id, openId: $openId) {
            sheet = .edit(row.id)
        } onAction: {
            deleting = row.id
        } content: {
            rowCard(row, isPaused: false)
        }
        .frame(height: Self.rowHeight)
        .scaleEffect(scale)
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

                    if isPaused {
                        Label("止めています", systemImage: "pause.circle")
                            .font(.caption2)
                            .foregroundStyle(Palette.amber)
                    } else {
                        Text(Self.nextText(row.next))
                            .font(.caption2)
                            .foregroundStyle(Palette.mist)
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
    static let purpose = "決まった日に、記録をひとりでに入れます"

    var hint: [String] {
        if model.rows.isEmpty {
            [Self.purpose]
        } else {
            [Self.purpose, "長押しで並べ替え、下の枠に置くと止められます"]
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

    var liftPreviewCenter: CGPoint? {
        if lift != nil {
            return CGPoint(
                x: boardFrame.midX,
                y: boardFrame.minY + liftedCenterY
            )
        }

        guard
            let hiddenLift,
            let frame = hiddenFrames[hiddenLift.id]
        else {
            return nil
        }

        return CGPoint(
            x: frame.midX + hiddenLift.offset.width,
            y: frame.midY + hiddenLift.offset.height
        )
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

        isOverHideZone = zones.isOverHide(location, from: boardFrame.origin)

        autoScroll.follow(
            y: location.y + boardFrame.origin.y,
            bottom: zones.hide.isEmpty ? nil : zones.hide.minY
        ) { delta in
            let shifted = CGPoint(x: location.x, y: location.y + delta)
            follow(row, at: index, to: shifted)
        }

        guard !isOverHideZone else {
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

        if isOverHideZone {
            let id = lift.id

            withAnimation(.snappy) {
                self.lift = nil
                isOverHideZone = false
            }

            Task {
                await model.hide(id)
            }

            return
        }

        withAnimation(.snappy) {
            self.lift = nil
        }

        Task {
            await model.finishMoving()
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
