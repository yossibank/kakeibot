import Core
import FeatureModels
import SwiftUI

public struct StampListView: View {
    private let parts: ScreenParts

    public init(parts: ScreenParts) {
        self.parts = parts
    }

    public var body: some View {
        SettingsBoardPage(StampBoard(parts: parts))
    }
}

#Preview {
    if let parts = ScreenParts.preview() {
        NavigationStack {
            StampListView(parts: parts)
        }
    }
}
