struct Memo<Key: Equatable, Value> {
    private var key: Key?
    private var value: Value?
}

extension Memo {
    mutating func value(
        for key: Key,
        make: () -> Value
    ) -> Value {
        if let value,
           self.key == key {
            return value
        }

        let made = make()

        self.key = key
        value = made

        return made
    }
}
