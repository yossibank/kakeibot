public struct ReminderTime: Hashable, Comparable, Sendable {
    public let hour: Int
    public let minute: Int

    public init?(
        hour: Int,
        minute: Int
    ) {
        guard (0...23).contains(hour), (0...59).contains(minute) else {
            return nil
        }

        self.hour = hour
        self.minute = minute
    }
}

public extension ReminderTime {
    static let morning = Self(checkedHour: 9, minute: 0)
    static let evening = Self(checkedHour: 21, minute: 0)

    init?(_ text: String) {
        let parts = text.split(separator: ":")

        guard
            parts.count == 2,
            parts.allSatisfy({ $0.count == 2 }),
            let hour = Int(parts[0]),
            let minute = Int(parts[1])
        else {
            return nil
        }

        self.init(hour: hour, minute: minute)
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.hour, lhs.minute) < (rhs.hour, rhs.minute)
    }
}

extension ReminderTime: CustomStringConvertible {
    public var description: String {
        let hour = hour < 10 ? "0\(hour)" : "\(hour)"
        let minute = minute < 10 ? "0\(minute)" : "\(minute)"
        return "\(hour):\(minute)"
    }
}

extension ReminderTime: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)

        guard let time = ReminderTime(text) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid time: \(text)"
            )
        }

        self = time
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

private extension ReminderTime {
    init(
        checkedHour hour: Int,
        minute: Int
    ) {
        self.hour = hour
        self.minute = minute
    }
}
