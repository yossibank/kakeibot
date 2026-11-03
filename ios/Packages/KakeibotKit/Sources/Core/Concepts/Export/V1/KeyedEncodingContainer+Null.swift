extension KeyedEncodingContainer {
    mutating func encodeOrNull(
        _ value: (some Encodable)?,
        forKey key: Key
    ) throws {
        guard let value else {
            try encodeNil(forKey: key)
            return
        }

        try encode(value, forKey: key)
    }
}
