import Core
import DesignSystem
import Store
import SwiftUI

extension WalletListView {
    enum Destination: Hashable {
        case new
        case edit(Wallet.ID)
    }

    nonisolated static let space = "WalletBoard"

    static let rowHeight = WalletRowCard<WalletRowIcon>.height
    static let grid = SettingsBoardGrid(columns: 1, itemHeight: rowHeight, spacing: 12)

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
        guard !model.needsHideConfirmation(of: wallet) else {
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
        case .new: WalletEditModel(database: database)
        case let .edit(id): WalletEditModel(database: database, editing: id)
        }
    }
}
