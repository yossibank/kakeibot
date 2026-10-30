import Core
import DesignSystem
import SwiftUI

struct EntryRouteRow: View {
    let model: EntryModel
    let onUse: (EntryModel.TransferRoute) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(model.frequentRoutes, id: \.self) { route in
                    button(route)
                }
            }
            .fixedSize()
            .padding(.vertical, 1)
        }
        .scrollIndicators(.hidden)
        .sharesTextScale(id: model.frequentRoutes)
    }
}

private extension EntryRouteRow {
    func button(_ route: EntryModel.TransferRoute) -> some View {
        let isApplied = model.walletId == route.walletId && model.toWalletId == route.toWalletId
        let source = model.wallet(route.walletId)?.name ?? ""
        let destination = model.wallet(route.toWalletId)?.name ?? ""

        return ChipButton(isSelected: isApplied) {
            onUse(route)
        } content: {
            HStack(spacing: 4) {
                Text(source)
                    .sharedTextScale()

                Image(systemName: "arrow.right")
                    .sansFont(.micro, weight: .semibold)
                    .foregroundStyle(Palette.accent)

                Text(destination)
                    .sharedTextScale()
            }
        }
    }
}
