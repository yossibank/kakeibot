extension Int {
    init?(
        asciiDigits text: Substring,
        count: Int
    ) {
        guard
            text.utf8.count == count,
            text.utf8.allSatisfy({ (UInt8(ascii: "0")...UInt8(ascii: "9")).contains($0) })
        else {
            return nil
        }

        self.init(text)
    }

    static func paddedText(
        _ value: Int,
        count: Int
    ) -> String {
        let text = String(value)
        return String(repeating: "0", count: Swift.max(0, count - text.count)) + text
    }
}
