import Core
import FeatureModels
import SwiftUI

public extension View {
    func tabScreen(
        _ model: some TabScreenModel,
        today: LocalDate,
        round: ObservationRound
    ) -> some View {
        loadFailed(model.isLoadFailed) {
            round.restart()
        }
        .onChange(of: today, initial: true) { _, today in
            model.setToday(today)
        }
    }
}
