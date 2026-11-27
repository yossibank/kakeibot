import Store

public extension ErrorNotice {
    nonisolated static let storageFullMessage = "\(DeviceName.current) の空き容量が足りません"

    func show(
        _ message: String,
        for error: any Error
    ) {
        show(AppDatabase.isStorageFull(error) ? Self.storageFullMessage : message)
    }
}
