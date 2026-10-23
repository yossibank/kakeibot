public extension [String?] {
    var rowDetail: String? {
        let parts = compactMap(\.self)

        return parts.isEmpty ? nil : parts.joined(separator: "・")
    }
}
