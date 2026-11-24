import SwiftUI

public struct RecurringListView: View {
    private let board: RecurringBoard

    init(board: RecurringBoard) {
        self.board = board
    }

    public var body: some View {
        SettingsBoardPage(board)
    }
}
