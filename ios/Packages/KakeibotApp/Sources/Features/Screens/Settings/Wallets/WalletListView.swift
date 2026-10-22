import Core
import DesignSystem
import Store
import SwiftUI

public struct WalletListView: View {
    @State private var drag = SettingsDrag<Wallet.ID>()
    @State private var model: WalletListModel
    @State private var hintFlag: SettingsScreenFlag
    @State private var destination: Destination?
    @State private var openId: Wallet.ID?
    @State private var hiddenId: Wallet.ID?
    @State private var deletion: Deletion?
    @State private var isConfirmingDeleteHidden = false
    @State private var hiddenList: SettingsScreenFlag
    @State private var hiding: Wallet?
    @State private var isConfirmingHide = false
    @State private var deleting: Wallet?
    @State private var isConfirmingDelete = false

    @Environment(\.themeStyle.corner) private var corner

    private let database: AppDatabase

    public init(database: AppDatabase) {
        _model = State(initialValue: WalletListModel(database: database))
        let hintFlag = SettingsScreenFlag.closedHint(.wallets, in: database)
        _hintFlag = State(initialValue: hintFlag)
        let hiddenList = SettingsScreenFlag.openHiddenList(
            .wallets,
            in: database
        )
        _hiddenList = State(initialValue: hiddenList)
        self.database = database
    }

    public var body: some View {
        VStack(spacing: 14) {
            SettingsBackHeader("口座", hint: hintFlag)

            SettingsHint(
                flag: hintFlag,
                lines: [.move, .hide, .swipeDelete]
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
                    drag.origin = origin
                }
            }
            .scrollIndicators(.hidden)
            .scrollDisabled(drag.isLifting)
            .settingsAutoScroll(drag.autoScroll)
            .settingsDropZones($drag.zones, showing: drag.showZone)
            .settingsHideNotice($hiddenId) { id in
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
                AddButton("口座を追加") {
                    destination = .new
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .settingsLiftLayer(
            drag,
            scale: 1.03
        ) { id in
            floatingTile(id)
        }
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
        .navigationDestination(item: $destination) { destination in
            WalletEditSheet(model: editModel(for: destination)) { _ in
            } onDelete: { deletion in
                self.deletion = deletion
            }
            .toolbar(.hidden, for: .navigationBar)
            .environment(\.isSettingsEditPushed, true)
        }
        .confirmsWalletHide(
            balance: hidingBalance,
            isPresented: $isConfirmingHide
        ) {
            if let hiding {
                hide(hiding.id)
            }
        }
        .confirmsWalletDelete(isPresented: $isConfirmingDelete) {
            if let deleting {
                delete(deleting.id)
            }
        }
        .confirmation(
            isPresented: $isConfirmingDeleteHidden,
            systemImage: "trash",
            title: "非表示の口座をまとめて削除しますか",
            message: "記録がある口座は残ります。使っている固定費・テンプレート・評価額も消えます",
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

private extension WalletListView {
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
            ) {
                isConfirmingDeleteHidden = true
            }

            if hiddenList.isOn {
                ForEach(model.hidden) { wallet in
                    hiddenRow(wallet)
                }
            }
        }
    }

    func hiddenRow(_ wallet: Wallet) -> some View {
        let lifted = drag.hiddenOffset(of: wallet.id)
        let isLifted = lifted != nil
        let offset = lifted ?? .zero
        let opacity: Double = isLifted ? 0 : 0.5
        let layer: Double = isLifted ? 1 : 0

        return row(wallet)
            .opacity(opacity)
            .animation(nil, value: isLifted)
            .contentShape(.rect)
            .offset(offset)
            .settingsLiftFrame(
                drag,
                \.hiddenFrames,
                id: wallet.id,
                in: Self.space
            )
            .zIndex(layer)
            .onTapGesture {
                destination = .edit(wallet.id)
            }
            .gesture(
                LiftGesture(in: Self.space) { location in
                    followHidden(wallet.id, to: location)
                } onEnd: {
                    dropHidden()
                }
            )
    }

    @ViewBuilder
    func floatingTile(_ id: Wallet.ID) -> some View {
        let items = model.shown + model.hidden

        if let wallet = items.first(where: { $0.id == id }) {
            row(wallet)
        }
    }

    func movableRow(_ wallet: Wallet) -> some View {
        let isLifted = drag.isLifted(wallet.id)
        let index = model.shown.firstIndex(of: wallet) ?? 0
        let center = isLifted ? drag.liftedCenter : Self.grid.center(at: index)
        let opacity: Double = isLifted ? 0 : 1
        let layer: Double = isLifted ? 1 : 0

        return SwipeRow(id: wallet.id, openId: $openId, role: .hide) {
            destination = .edit(wallet.id)
        } onAction: {
            requestHide(wallet)
        } onDelete: {
            requestDelete(wallet)
        } content: {
            row(wallet)
        }
        .frame(height: Self.rowHeight)
        .opacity(opacity)
        .animation(nil, value: isLifted)
        .offset(y: center.y - Self.rowHeight / 2)
        .settingsLiftFrame(
            drag,
            \.rowFrames,
            id: wallet.id,
            in: Self.space
        )
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
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)

                Text(wallet.kind.title)
                    .textFont(.caption2)
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
    enum Destination: Hashable {
        case new
        case edit(Wallet.ID)
    }

    nonisolated static let space = "WalletBoard"
    static let rowHeight: CGFloat = 68
    static let grid = SettingsBoardGrid(
        columns: 1,
        itemHeight: rowHeight,
        spacing: 10
    )

    var boardHeight: CGFloat {
        Self.grid.height(slots: model.shown.count)
    }

    var hidingBalance: Int {
        hiding.map { model.balance(of: $0) } ?? 0
    }

    func follow(
        _ wallet: Wallet,
        to location: CGPoint
    ) {
        let index = model.shown.firstIndex(of: wallet) ?? 0
        let start = Self.grid.center(at: index)

        let center = drag.follow(wallet.id, from: start, to: location) { next in
            follow(wallet, to: next)
        }

        guard let center else {
            return
        }

        let target = Self.grid.index(at: center, count: model.shown.count)

        withAnimation(.snappy) {
            model.move(wallet.id, to: target)
        }
    }

    func drop() {
        switch drag.drop() {
        case let .hide(id):
            let wallet = model.shown.first { $0.id == id }

            withAnimation(.snappy) {
                model.cancelMoving()
            }

            if let wallet {
                requestHide(wallet)
            }
        case .move:
            Task {
                await model.finishMoving()
            }
        case nil:
            break
        }
    }

    func requestDelete(_ wallet: Wallet) {
        deleting = wallet
        isConfirmingDelete = true
    }

    func delete(_ id: Wallet.ID) {
        Task {
            deletion = await model.delete(id)
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
        drag.followHidden(id, to: location)
    }

    func dropHidden() {
        guard let id = drag.dropHidden() else {
            return
        }

        show(id)
    }

    func hide(_ id: Wallet.ID) {
        Task {
            if await model.hide(id) {
                hiddenId = id
            }
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

    func show(_ id: Wallet.ID) {
        Task {
            await model.show(id)
        }
    }

    func editModel(for destination: Destination) -> WalletEditModel {
        switch destination {
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
