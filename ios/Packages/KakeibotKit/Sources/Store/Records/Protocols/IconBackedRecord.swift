import Core

protocol IconBackedRecord: SortableRecord {
    var iconId: Icon.ID { get set }

    static var iconNotFound: any Error { get }
}
