import Core
import DesignSystem
import Store
import SwiftUI

public struct WalletListView: View {
    @State private var model: WalletListModel
    @State private var sheet: Sheet?
    @State private var lift: Lift?
    @State private var liftCount = 0
    @State private var openId: Wallet.ID?
    @State private var zones = SettingsDropZones()
    @State private var autoScroll = SettingsAutoScroll()
    @State private var contentOrigin: CGPoint = .zero
    @State private var hideHover = SettingsHideHover()
    @State private var hiddenId: Wallet.ID?
    @State private var hiddenList: SettingsScreenFlag
    @State private var hiding: Wallet?
    @State private var isConfirmingHide = false
    @State private var hiddenLift: SettingsHiddenLift<Wallet.ID>?
    @State private var isOverShowZone = false
    @State private var showCount = 0

    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeStyle.corner) private var corner

    private let database: AppDatabase

    public init(database: AppDatabase) {
        _model = State(initialValue: WalletListModel(database: database))
        let hiddenList = SettingsScreenFlag.openHiddenList(
            .wallets,
            in: database
        )
        _hiddenList = State(initialValue: hiddenList)
        self.database = database
    }

    public var body: some View {
        VStack(spacing: 14) {
            header

            SettingsHint(
                flag: .closedHint(.wallets, in: database),
                lines: [.move, .hide, .swipeHide]
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    board

                    if !model.hidden.isEmpty {
                        hiddenSection
                    }
                }
                .padding(.vertical, 8)
                .coordinateSpace(.named(Self.space))
                .onGeometryChange(for: CGPoint.self) { proxy in
                    proxy.frame(in: .global).origin
                } action: { origin in
                    contentOrigin = origin
                }
            }
            .scrollIndicators(.hidden)
            .scrollDisabled(lift != nil || hiddenLift != nil)
            .settingsAutoScroll(autoScroll)
            .settingsDropZones(
                $zones,
                showing: hiddenLift == nil ? nil : isOverShowZone
            )
            .settingsHideNotice($hiddenId) { id in
                show(id)
            }

            if lift != nil {
                SettingsHideTarget(zones: $zones, state: hideHover.state)
            } else {
                AddButton("口座を追加") {
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
            WalletEditSheet(model: editModel(for: sheet))
        }
        .confirmsWalletHide(
            balance: hidingBalance,
            isPresented: $isConfirmingHide
        ) {
            if let hiding {
                hide(hiding.id)
            }
        }
        .task {
            await model.observe()
        }
    }
}

private extension WalletListView {
    var header: some View {
        HStack {
            RingButton(systemImage: "chevron.left") {
                dismiss()
            }

            Spacer()

            Text("口座")
                .displayFont(.body)
                .tracking(4)
                .foregroundStyle(Palette.accent)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    var board: some View {
        ZStack(alignment: .top) {
            ForEach(model.shown) { wallet in
                movableRow(wallet)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: boardHeight, alignment: .top)
    }

    var hiddenSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SettingsHiddenTitle(
                flag: hiddenList,
                title: "非表示の口座",
                count: model.hidden.count
            )

            if hiddenList.isOn {
                ForEach(model.hidden) { wallet in
                    hiddenRow(wallet)
                }
            }
        }
    }

    func hiddenRow(_ wallet: Wallet) -> some View {
        let isLifted = hiddenLift?.id == wallet.id
        let offset = isLifted ? hiddenLift?.offset ?? .zero : .zero
        let scale: CGFloat = isLifted ? 1.03 : 1
        let shadow = Palette.shadow.opacity(isLifted ? 0.5 : 0)
        let opacity: Double = isLifted ? 1 : 0.5
        let layer: Double = isLifted ? 1 : 0

        return row(wallet)
            .opacity(opacity)
            .contentShape(.rect)
            .scaleEffect(scale)
            .shadow(color: shadow, radius: 16, y: 8)
            .offset(offset)
            .zIndex(layer)
            .onTapGesture {
                sheet = .edit(wallet.id)
            }
            .gesture(
                LiftGesture(in: Self.space) { location in
                    followHidden(wallet.id, to: location)
                } onEnd: {
                    dropHidden()
                }
            )
    }

    func movableRow(_ wallet: Wallet) -> some View {
        let isLifted = lift?.id == wallet.id
        let index = model.shown.firstIndex(of: wallet) ?? 0
        let y = isLifted ? liftedCenterY : centerY(at: index)
        let scale: CGFloat = isLifted ? 1.03 : 1
        let shadow = Palette.shadow.opacity(isLifted ? 0.5 : 0)
        let layer: Double = isLifted ? 1 : 0

        return SwipeRow(id: wallet.id, openId: $openId, role: .hide) {
            sheet = .edit(wallet.id)
        } onAction: {
            requestHide(wallet)
        } content: {
            row(wallet)
        }
        .frame(height: Self.rowHeight)
        .scaleEffect(scale)
        .shadow(color: shadow, radius: 16, y: 8)
        .offset(y: y - Self.rowHeight / 2)
        .zIndex(layer)
        .gesture(
            LiftGesture(in: Self.space) { location in
                follow(wallet, to: location)
            } onEnd: {
                drop()
            }
        )
    }

    func row(_ wallet: Wallet) -> some View {
        let balance = model.balance(of: wallet)
        let balanceColor = balance < 0 ? Palette.rose : Palette.accentStrong

        return HStack(spacing: 14) {
            IconImage(model.icon(for: wallet), size: 18)
                .foregroundStyle(Palette.accent)
                .frame(width: 40, height: 40)
                .background(
                    Palette.accent.opacity(.subtle),
                    in: .rect(cornerRadius: corner.radius(12))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: corner.radius(12))
                        .stroke(Palette.accent.opacity(.muted), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(wallet.name)
                    .font(.subheadline)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)

                Text(wallet.kind.title)
                    .font(.caption2)
                    .tracking(1)
                    .foregroundStyle(Palette.subtext)
            }

            Spacer(minLength: 8)

            Text(AmountText.text(balance))
                .displayFont(.body)
                .monospacedDigit()
                .foregroundStyle(balanceColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 16)
        .frame(height: Self.rowHeight)
        .card(cornerRadius: 18)
        .contentShape(.rect)
    }
}

private extension WalletListView {
    struct Lift {
        let id: Wallet.ID
        var y: CGFloat
        var grab: CGFloat?
    }

    enum Sheet: Hashable, Identifiable {
        case new
        case edit(Wallet.ID)

        var id: Self {
            self
        }
    }

    nonisolated static let space = "WalletBoard"
    static let rowHeight: CGFloat = 68
    static let spacing: CGFloat = 10
    var boardHeight: CGFloat {
        let count = CGFloat(model.shown.count)
        let gaps = Self.spacing * max(count - 1, 0)
        return Self.rowHeight * count + gaps
    }

    var hidingBalance: Int {
        hiding.map { model.balance(of: $0) } ?? 0
    }

    var liftedCenterY: CGFloat {
        guard let lift else {
            return 0
        }

        return lift.y + (lift.grab ?? 0)
    }

    func centerY(at index: Int) -> CGFloat {
        let step = Self.rowHeight + Self.spacing
        return step * CGFloat(index) + Self.rowHeight / 2
    }

    func index(at y: CGFloat) -> Int {
        let step = Self.rowHeight + Self.spacing
        let index = Int(y / step)
        return min(max(index, 0), model.shown.count - 1)
    }

    func follow(
        _ wallet: Wallet,
        to location: CGPoint
    ) {
        if lift == nil {
            let index = model.shown.firstIndex(of: wallet) ?? 0
            let start = centerY(at: index)

            withAnimation(.snappy(duration: 0.2)) {
                lift = Lift(id: wallet.id, y: start)
            }

            liftCount += 1
        }

        guard var current = lift else {
            return
        }

        if current.grab == nil {
            current.grab = current.y - location.y
        }

        current.y = location.y
        lift = current
        let isInside = zones.isOverHide(location, from: contentOrigin)
        hideHover.update(isInside: isInside)

        autoScroll.follow(
            y: location.y + contentOrigin.y,
            bottom: zones.hide.isEmpty ? nil : zones.hide.minY
        ) { delta in
            let shifted = CGPoint(x: location.x, y: location.y + delta)
            follow(wallet, to: shifted)
        }

        guard !hideHover.isInside else {
            return
        }

        let target = index(at: liftedCenterY)

        withAnimation(.snappy) {
            model.move(wallet.id, to: target)
        }
    }

    func drop() {
        autoScroll.stop()

        guard let lift else {
            return
        }

        if hideHover.isArmed {
            let wallet = model.shown.first { $0.id == lift.id }

            withAnimation(.snappy) {
                self.lift = nil
                hideHover.reset()
                model.cancelMoving()
            }

            if let wallet {
                requestHide(wallet)
            }

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

    func requestHide(_ wallet: Wallet) {
        guard model.balance(of: wallet) == 0 else {
            hiding = wallet
            isConfirmingHide = true
            return
        }

        hide(wallet.id)
    }

    func followHidden(
        _ id: Wallet.ID,
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
        isOverShowZone = zones.isOverShow(location, from: contentOrigin)
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

    func hide(_ id: Wallet.ID) {
        Task {
            if await model.hide(id) {
                hiddenId = id
            }
        }
    }

    func show(_ id: Wallet.ID) {
        Task {
            await model.show(id)
        }
    }

    func editModel(for sheet: Sheet) -> WalletEditModel {
        switch sheet {
        case .new:
            WalletEditModel(database: database)
        case let .edit(id):
            WalletEditModel(database: database, editing: id)
        }
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())

        NavigationStack {
            WalletListView(database: database)
        }
    }
}
