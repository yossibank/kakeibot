import AppFeature
import SwiftUI

@main
@MainActor
struct KakeibotApp {}

extension KakeibotApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
