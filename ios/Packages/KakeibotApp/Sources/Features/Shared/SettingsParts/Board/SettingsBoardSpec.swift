import Core
import CoreGraphics
import FeatureModels
import SwiftUI

@MainActor
protocol SettingsBoardSpec {
    associatedtype Model: SettingsBoardListModel
    associatedtype Header: View = EmptyView
    associatedtype Lead: View = EmptyView
    associatedtype ScaleID: Equatable = Int
    associatedtype Tile: View
    associatedtype Editor: SettingsEditSheet

    var parts: ScreenParts { get }
    var title: String { get }
    var hiddenTitle: String { get }
    var deleteHiddenTitle: String { get }
    var deleteHiddenMessage: String { get }
    var grid: SettingsBoardGrid { get }
    var space: String { get }
    var liftScale: CGFloat { get }
    var layout: SettingsBoardLayout { get }
    var hideMessage: String { get }
    var scrollMargin: CGFloat { get }

    func makeModel() -> Model
    func intro(hint: SettingsFold, in model: Model) -> SettingsIntroCard
    func emptyNote(in model: Model) -> (systemImage: String, text: String)
    func addTitle(in model: Model) -> String
    func header(in model: Model) -> Header
    func lead(in model: Model) -> Lead
    func scaleID(in model: Model) -> ScaleID?
    func newDestination(in model: Model) -> Model.State.Destination
    func destination(editing item: Model.Item) -> Model.State.Destination
    func itemID(of destination: Model.State.Destination) -> Model.Item.ID?

    func tile(
        _ item: Model.Item,
        in model: Model,
        isHidden: Bool
    ) -> Tile

    func editModel(for destination: Model.State.Destination) -> Editor.EditModel

    func editor(
        for destination: Model.State.Destination,
        onDelete: @escaping (Deletion) -> Void,
        onHide: @escaping () -> Void
    ) -> Editor

    func hideConfirmation(
        of item: Model.Item,
        in model: Model
    ) -> SettingsConfirmation?

    func deleteConfirmation(
        of item: Model.Item,
        in model: Model
    ) -> SettingsConfirmation?
}

extension SettingsBoardSpec {
    typealias Destination = Model.State.Destination

    var layout: SettingsBoardLayout {
        .tiles
    }

    var hideMessage: String {
        "非表示にしました"
    }

    var scrollMargin: CGFloat {
        0
    }

    func editor(
        for destination: Destination,
        onDelete: @escaping (Deletion) -> Void,
        onHide: @escaping () -> Void
    ) -> Editor {
        Editor(model: editModel(for: destination), onDelete: onDelete, onHide: onHide)
    }

    func hideConfirmation(
        of _: Model.Item,
        in _: Model
    ) -> SettingsConfirmation? {
        nil
    }

    func deleteConfirmation(
        of _: Model.Item,
        in _: Model
    ) -> SettingsConfirmation? {
        nil
    }
}

extension SettingsBoardSpec {
    func addTitle(in _: Model) -> String {
        "\(title)を追加"
    }
}

extension SettingsBoardSpec where Model: SettingsBoardDatabaseModel {
    func makeModel() -> Model {
        Model(parts: parts)
    }
}

extension SettingsBoardSpec where Lead == EmptyView {
    func lead(in _: Model) -> EmptyView {
        EmptyView()
    }
}

extension SettingsBoardSpec where ScaleID == Int {
    func scaleID(in _: Model) -> Int? {
        nil
    }
}

extension SettingsBoardSpec where Header == EmptyView {
    func header(in _: Model) -> EmptyView {
        EmptyView()
    }
}

extension SettingsBoardSpec
    where Model.State.Destination == SettingsBoardDestination<Model.Item.ID> {
    func newDestination(in _: Model) -> Destination {
        .new
    }

    func destination(editing item: Model.Item) -> Destination {
        .edit(item.id)
    }

    func itemID(of destination: Destination) -> Model.Item.ID? {
        destination.editingID
    }
}
