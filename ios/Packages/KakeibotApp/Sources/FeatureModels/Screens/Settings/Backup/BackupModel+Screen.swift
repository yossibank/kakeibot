public extension BackupModel {
    enum Dialog: Hashable, Sendable {
        case exporter
        case importer
        case restore
    }

    struct Presented: ScreenEditable {
        public var dialog = Shown<Dialog>()
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
        done?.message
    }

    func press(_ row: BackupModel.Row) {
        if pressed != row {
            pressed = row
        }
    }
}

extension BackupModel.State {
    func finishWorking() {
        if pressed != nil {
            pressed = nil
        }
    }
}
