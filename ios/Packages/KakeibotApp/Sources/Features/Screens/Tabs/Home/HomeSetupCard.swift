import DesignSystem
import FeatureModels
import SwiftUI

struct HomeSetupCard: View {
    let model: SetupModel
    let onOpen: (SetupItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            CardHeader(
                "あと \(model.output.cardItems.count) つで準備がそろいます",
                onClose: {
                    Task {
                        await model.closeCard()
                    }
                }
            )

            SetupList(model.output.cardItems, model: model, onOpen: onOpen)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
        .card()
        .animation(.snappy, value: model.output.cardItems)
    }
}
