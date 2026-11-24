import Core
import FeatureModels
import SwiftUI

public struct CategoryListView: View {
    private let board: CategoryBoard

    public init(
        parts: ScreenParts,
        kind: EntryCategory.Kind = .expense
    ) {
        self.init(board: CategoryBoard(parts: parts, kind: kind))
    }

    init(board: CategoryBoard) {
        self.board = board
    }

    public var body: some View {
        SettingsBoardPage(board)
    }
}

#Preview {
    if let parts = ScreenParts.preview() {
        NavigationStack {
            CategoryListView(parts: parts)
        }
    }
}
