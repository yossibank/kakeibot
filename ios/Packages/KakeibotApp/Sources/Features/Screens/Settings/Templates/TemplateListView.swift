import Core
import FeatureModels
import Store
import SwiftUI

public struct TemplateListView: View {
    private let parts: ScreenParts

    public init(parts: ScreenParts) {
        self.parts = parts
    }

    public var body: some View {
        SettingsBoardPage(TemplateBoard(parts: parts))
    }
}

#Preview {
    if let parts = ScreenParts.preview() {
        NavigationStack {
            TemplateListView(parts: parts)
        }
    }
}
