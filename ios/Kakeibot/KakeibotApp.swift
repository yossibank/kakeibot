import AppFeature
import SwiftUI

@main
struct KakeibotApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }

    init() {
        AppLaunch.prepare()
    }
}
