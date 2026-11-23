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

    var controller: SettingsBoardController<WalletListModel> {
        SettingsBoardController(
            model: model,
            drag: drag,
            grid: Self.grid,
            hiddenId: $hiddenId,
            deletion: $deletion,
            bulkDelete: $bulkDelete
        )
    }

    func drop() {
        controller.drop { id in
            let wallet = model.shown.first { $0.id == id }

            withAnimation(.snappy) {
                model.cancelMoving()
            }

            if let wallet {
                requestHide(wallet)
            }
        }
    }

    func requestDelete(_ wallet: Wallet) {
        deleting = wallet
        isConfirmingDelete = true
    }

    func requestHide(_ wallet: Wallet) {
        guard !model.needsHideConfirmation(of: wallet) else {
            hiding = wallet
            isConfirmingHide = true
            return
        }

        controller.hide(wallet.id)
    }

    func editModel(for destination: Destination) -> WalletEditModel {
        switch destination {
        case .new: WalletEditModel(database: database)
        case let .edit(id): WalletEditModel(database: database, editing: id)
        }
    }
}
