import AppFeature
import SwiftUI

@main
struct KakeibotApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }

    init() {
        AppLaunch.prepare()
    }
}
