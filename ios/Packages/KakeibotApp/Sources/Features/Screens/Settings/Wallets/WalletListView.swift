import Core
import FeatureModels
import Store
import SwiftUI

public struct WalletListView: View {
    private let parts: ScreenParts

    public init(parts: ScreenParts) {
        self.parts = parts
    }

    public var body: some View {
        SettingsBoardPage(WalletBoard(parts: parts))
    }
}

#Preview {
    if let parts = ScreenParts.preview() {
        NavigationStack {
            WalletListView(parts: parts)
        }
    }
}
