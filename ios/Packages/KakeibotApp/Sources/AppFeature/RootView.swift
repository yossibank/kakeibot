import Features
import Notifications
import SwiftUI

@MainActor
public struct RootView {
    public init() {}
}

extension RootView: View {
    public var body: some View {
        Text("Kakeibot")
    }
}

#Preview {
    RootView()
}
