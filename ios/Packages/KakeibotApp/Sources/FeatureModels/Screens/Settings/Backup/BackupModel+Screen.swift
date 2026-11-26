public extension BackupModel {
    enum Presented: Hashable, Sendable {
        case exporter
        case importer
        case restore
    }

    enum Row: Equatable, Sendable {
        case export(FileKind)
        case importFile
        case previous(Previous)
    }
}

public extension BackupModel.State {
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
