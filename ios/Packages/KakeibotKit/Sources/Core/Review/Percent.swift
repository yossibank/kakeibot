public enum Percent {
    public static func floor(_ part: Int, of whole: Int) -> Int {
        guard whole > 0 else {
            return 0
        }

        return min(max(part * 100 / whole, 0), 100)
    }
}
