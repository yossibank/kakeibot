import Core
import DesignSystem
import SwiftUI

struct EntryRouteRow: View {
    let model: EntryModel
    let onUse: (EntryModel.TransferRoute) -> Void

    var body: some View {
        let routes = model.output.frequentRoutes

        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(routes, id: \.self) { route in
                    button(route)
                }
            }
            .fixedSize()
            .padding(.vertical, 1)
        }
        .scrollIndicators(.hidden)
        .sharesTextScale(id: routes)
    }
}

private extension EntryRouteRow {
    func button(_ route: EntryModel.TransferRoute) -> some View {
        let isApplied = model.state.payment.walletId == route.walletId && model.state.payment
            .toWalletId == route.toWalletId
        let source = model.output.wallet(route.walletId)?.name ?? ""
        let destination = model.output.wallet(route.toWalletId)?.name ?? ""

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
