import Core

public extension BackupModel {
    enum Dialog: Hashable, Sendable {
        case exporter
        case importer
        case restore
    }

    struct Presented: ScreenEditable {
        public var dialog = Shown<Dialog>()

        public internal(set) var file: BackupModel.BackupFile?
        public internal(set) var pending: ExportV1?
        public internal(set) var pressed: Row?
    }

    @MainActor
    struct Notices: ScreenNotices {
        public let error: ErrorNotice

        public internal(set) var done: Done?

        init(wait: ScreenWait) {
            self.error = ErrorNotice(wait: wait)
        }
    }

    enum Done: Hashable, Sendable {
        case exported
        case restored
    }

    enum Row: Equatable, Sendable {
        case export(FileKind)
        case importFile
        case previous(Previous)
    }
}

public extension BackupModel.Done {
    var message: String {
        switch self {
        case .exported: "書き出しました"
        case .restored: "読み込みました"
        }
    }
}

public extension BackupModel.State {
    var doneMessage: String? {
        notices.done?.message
    }

    func press(_ row: BackupModel.Row) {
        if presented.pressed != row {
            presented.pressed = row
        }
    }
}

extension BackupModel.State {
    func finishWorking() {
        if presented.pressed != nil {
            presented.pressed = nil
        }
    }
}
