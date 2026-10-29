import Core
import DesignSystem
import Store
import SwiftUI

public struct WalletListView: View {
    @State var drag = SettingsDrag<Wallet.ID>()
    @State var model: WalletListModel
    @State var hiddenId: Wallet.ID?
    @State var deletion: Deletion?
    @State var hiding: Wallet?
    @State var isConfirmingHide = false
    @State var deleting: Wallet?
    @State var isConfirmingDelete = false

    @State private var hintFlag: SettingsScreenFlag
    @State private var destination: Destination?
    @State private var openId: Wallet.ID?
    @State private var isConfirmingDeleteHidden = false
    @State private var hiddenList: SettingsScreenFlag

    let database: AppDatabase

    public init(database: AppDatabase) {
        let hintFlag = SettingsScreenFlag.closedHint(.wallets, in: database)
        let hiddenList = SettingsScreenFlag.openHiddenList(.wallets, in: database)
        let model = WalletListModel(database: database)

        _model = State(initialValue: model)
        _hintFlag = State(initialValue: hintFlag)
        _hiddenList = State(initialValue: hiddenList)

        self.database = database
    }

    public var body: some View {
        VStack(spacing: 16) {
            SettingsBackHeader("口座", hint: hintFlag)

            SettingsHint(flag: hintFlag, lines: [.move, .hide, .swipeDelete])

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if model.shown.isEmpty {
                        SettingsEmptyNote(
                            systemImage: "building.columns",
                            text: "口座を足すと、ここに並びます"
                        )
                    }

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
                SettingsHideTarget(zones: $drag.zones, isArmed: drag.isOverHide)
            } else {
                AddButton("口座を追加") {
                    destination = .new
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .settingsLiftLayer(drag, scale: 1.03) { id in
            floatingTile(id)
        }
        .sharesTextScale(id: model.shown + model.hidden)
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .background {
            Backdrop()
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .haptic(.impact(weight: .medium), trigger: drag.liftCount)
        .haptic(.selection, trigger: model.movingOrder)
        .haptic(.success, trigger: drag.showCount)
        .navigationDestination(item: $destination) { destination in
            WalletEditSheet(model: editModel(for: destination)) { _ in } onDelete: { deletion in
                self.deletion = deletion
            } onHide: {
                if case let .edit(id) = destination {
                    hiddenId = id
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .environment(\.isSettingsEditPushed, true)
        }
        .confirmsWalletHide(balance: hidingBalance, isPresented: $isConfirmingHide) {
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
        VStack(alignment: .leading, spacing: 12) {
            SettingsHiddenTitle(flag: hiddenList, title: "非表示の口座", count: model.hidden.count) {
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
            .settingsLiftFrame(drag, \.hiddenFrames, id: wallet.id, in: Self.space)
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
        .settingsLiftFrame(drag, \.rowFrames, id: wallet.id, in: Self.space)
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
        WalletRowCard(
            name: wallet.name,
            kind: wallet.kind,
            amount: model.balance(of: wallet)
        ) {
            WalletRowIcon(icon: model.icon(for: wallet))
        }
        .contentShape(.rect)
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
