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
    }
}

private extension EntryRouteRow {
    static let height: CGFloat = 34

    func button(_ route: EntryModel.TransferRoute) -> some View {
        let isApplied = model.walletId == route.walletId && model.toWalletId == route.toWalletId
        let source = model.wallet(route.walletId)?.name ?? ""
        let destination = model.wallet(route.toWalletId)?.name ?? ""
        let stroke = isApplied ? Palette.accent : Palette.accent.opacity(.soft)

        return Button {
            onUse(route)
        } label: {
            HStack(spacing: 6) {
                Text(source)

                Image(systemName: "arrow.right")
                    .sansFont(.micro, weight: .semibold)
                    .foregroundStyle(Palette.accent)

                Text(destination)
            }
            .textFont(size: .caption)
            .foregroundStyle(Palette.text)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 12)
            .frame(height: Self.height)
            .background(EntrySheet.categoryFill(isApplied), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(stroke, lineWidth: 1)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
