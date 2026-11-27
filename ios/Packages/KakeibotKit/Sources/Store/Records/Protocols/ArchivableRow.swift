import Foundation

public protocol ArchivableRow: HidableRow {
    var archivedAt: Date? { get }
}
