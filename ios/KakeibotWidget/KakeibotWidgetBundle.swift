import SwiftUI
import WidgetFeature
import WidgetKit

@main
@MainActor
struct KakeibotWidgetBundle {}

extension KakeibotWidgetBundle: WidgetBundle {
    var body: some Widget {
        KakeibotWidget()
    }
}
