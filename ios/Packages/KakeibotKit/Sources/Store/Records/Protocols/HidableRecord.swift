import Foundation
import GRDB

protocol HidableRecord: SortableRecord {
    static func setHidden(
        _ id: ID,
        _ isHidden: Bool,
        in db: Database,
        at now: Date
    ) throws
}
