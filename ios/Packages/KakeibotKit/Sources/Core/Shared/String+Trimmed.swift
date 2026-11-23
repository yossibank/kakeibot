import Foundation

public extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedOrNil: String? {
        let trimmed = trimmed
        return trimmed.isEmpty ? nil : trimmed
    }
}
