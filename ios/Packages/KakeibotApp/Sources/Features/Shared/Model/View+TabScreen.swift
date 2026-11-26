import FeatureModels
import SwiftUI

public extension View {
    func tabScreen(
        _ model: some TabScreenModel,
        round: ObservationRound
    ) -> some View {
        loadFailed(model.isLoadFailed) {
            round.restart()
        }
    }
}
