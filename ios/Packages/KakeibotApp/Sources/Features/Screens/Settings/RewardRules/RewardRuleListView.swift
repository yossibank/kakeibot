import Core
import FeatureModels
import Store
import SwiftUI

public struct RewardRuleListView: View {
    private let board: RewardRuleBoard

    public init(parts: ScreenParts) {
        self.init(board: RewardRuleBoard(parts: parts))
    }

    init(board: RewardRuleBoard) {
        self.board = board
    }

    public var body: some View {
        SettingsBoardPage(board)
    }
}

#Preview {
    if let parts = ScreenParts.preview() {
        NavigationStack {
            RewardRuleListView(parts: parts)
        }
    }
}
