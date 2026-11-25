import FeatureModels
import Features
import SwiftUI

struct MainOutcomeSignal<Value>: View {
    let outcome: () -> ScreenOutcome<Value>
    let onOutcome: (Value) -> Void

    var body: some View {
        Color.clear
            .onOutcome(outcome(), perform: onOutcome)
    }
}
