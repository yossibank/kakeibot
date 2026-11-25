public extension BackupModel {
    enum Picker: Hashable, Sendable {
        case exporter
        case importer
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

    func pick(_ picker: BackupModel.Picker) {
        if self.picker != picker {
            self.picker = picker
        }
    }

    func close(_ picker: BackupModel.Picker) {
        if self.picker == picker {
            self.picker = nil
        }
    }
}

extension BackupModel.State {
    func finishWorking() {
        isWorking = false

        if pressed != nil {
            pressed = nil
        }
    }
}
