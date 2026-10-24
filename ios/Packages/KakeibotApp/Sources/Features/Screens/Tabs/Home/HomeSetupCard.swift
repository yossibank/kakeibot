import DesignSystem
import SwiftUI

struct HomeSetupCard: View {
    let model: SetupModel
    let onOpen: (SetupItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HomeCardHeader(title: "あと \(model.cardItems.count) つで準備がそろいます") {
                Task {
                    await model.closeCard()
                }
            }

            SetupList(model.cardItems, model: model, onOpen: onOpen)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
        .card()
        .animation(.snappy, value: model.cardItems)
    }
}
