import Foundation

public struct AppVersion: Comparable, Hashable, Sendable {
    public let parts: [Int]

    public init?(_ text: String) {
        let pieces = text.split(separator: ".", omittingEmptySubsequences: false)

        let numbers = pieces.compactMap { piece in
            piece.allSatisfy { ("0"..."9").contains($0) } ? Int(piece) : nil
        }

        guard
            !pieces.isEmpty,
            numbers.count == pieces.count
        else {
            return nil
        }

        var parts = numbers

        while parts.count > 1, parts.last == 0 {
            parts.removeLast()
        }

        self.parts = parts
    }
}

public extension AppVersion {
    static func < (
        lhs: AppVersion,
        rhs: AppVersion
    ) -> Bool {
        let count = max(lhs.parts.count, rhs.parts.count)

        for index in 0..<count {
            let left = lhs.parts.indices.contains(index) ? lhs.parts[index] : 0
            let right = rhs.parts.indices.contains(index) ? rhs.parts[index] : 0

            if left != right {
                return left < right
            }
        }

        return false
    }

    static func isNewer(
        _ latest: String,
        than seen: String?
    ) -> Bool {
        guard let latest = AppVersion(latest) else {
            return false
        }

        guard
            let seen,
            let seenVersion = AppVersion(seen)
        else {
            return true
        }

        return latest > seenVersion
    }
}
