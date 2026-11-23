import Core
import CoreGraphics
import Store
import SwiftUI

@MainActor
protocol SettingsBoardSpec {
    associatedtype Model: SettingsBoardListModel
    associatedtype Destination: Hashable
    associatedtype Header: View = EmptyView
    associatedtype Tile: View
    associatedtype Editor: View

    var database: AppDatabase { get }
    var screen: SettingsScreen { get }
    var title: String { get }
    var emptyNote: (systemImage: String, text: String) { get }
    var hiddenTitle: String { get }
    var deleteHiddenTitle: String { get }
    var deleteHiddenMessage: String { get }
    var grid: SettingsBoardGrid { get }
    var space: String { get }
    var liftScale: CGFloat { get }
    var hideMessage: String { get }
    var scrollMargin: CGFloat { get }

    func makeModel() -> Model
    func intro(flag: SettingsScreenFlag) -> SettingsIntroCard
    func addTitle(in model: Model) -> String
    func header(in model: Model) -> Header
    func newDestination(in model: Model) -> Destination
    func destination(editing item: Model.Item) -> Destination
    func itemID(of destination: Destination) -> Model.Item.ID?

    func tile(
        _ item: Model.Item,
        in model: Model,
        isHidden: Bool
    ) -> Tile

    func editor(
        for destination: Destination,
        onDelete: @escaping (Deletion) -> Void,
        onHide: @escaping () -> Void
    ) -> Editor
}

extension SettingsBoardSpec {
    var hideMessage: String {
        "非表示にしました"
    }

    var scrollMargin: CGFloat {
        0
    }
}

extension SettingsBoardSpec where Header == EmptyView {
    func header(in _: Model) -> EmptyView {
        EmptyView()
    }
}
