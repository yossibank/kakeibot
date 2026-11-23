import SwiftUI

public struct RecurringListView: View {
    private let model: RecurringListModel

    public init(model: RecurringListModel) {
        self.model = model
    }

    public var body: some View {
        SettingsBoardPage(RecurringBoard(model: model))
    }
}
