import DesignSystem
import Store

public extension ErrorNotice {
    static let storageFullMessage = "iPhone の空き容量が足りません"

    mutating func show(
        _ message: String,
        for error: any Error
    ) {
        show(AppDatabase.isStorageFull(error) ? Self.storageFullMessage : message)
    }
}
