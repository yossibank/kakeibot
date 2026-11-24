@MainActor
final class DerivedTable<Key: Hashable, Value> {
    private var cells: [Key: Derived<Value>] = [:]
}

extension DerivedTable {
    var count: Int {
        cells.count
    }

    func value(
        for key: Key,
        _ make: () -> Value
    ) -> Value {
        if let cell = cells[key] {
            return cell.value(make)
        }

        let cell = Derived<Value> { [weak self] in
            self?.cells[key] = nil
        }

        cells[key] = cell

        return cell.value(make)
    }
}
