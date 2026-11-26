import Core
import Foundation
import GRDB

public struct SettingKey<Value: Sendable>: Sendable {
    public let defaultValue: Value

    let read: @Sendable (Database) throws -> Value
    let write: @Sendable (Value, Database) throws -> Void
}

extension SettingKey {
    init(
        _ key: Setting.Key,
        default defaultValue: Value,
        decode: @escaping @Sendable (String) -> Value?,
        encode: @escaping @Sendable (Value) -> String?
    ) {
        self.defaultValue = defaultValue

        self.read = { db in
            let setting = try Setting.fetchOne(db, key: key)
            return setting.flatMap { decode($0.value) } ?? defaultValue
        }

        self.write = { value, db in
            guard let text = encode(value) else {
                _ = try Setting.deleteOne(db, key: key)
                return
            }

            let setting = Setting(key: key, value: text)

            try setting.save(db)
        }
    }

    init<Wrapped: LosslessStringConvertible>(optional key: Setting.Key) where Value == Wrapped? {
        self.init(
            key,
            default: nil,
            decode: { Wrapped($0) },
            encode: { $0?.description }
        )
    }

    init<Element: RawRepresentable<String> & Hashable>(
        set key: Setting.Key
    ) where Value == Set<Element> {
        self.init(
            key,
            default: [],
            decode: { text in
                let elements = text.split(separator: ",").compactMap { name in
                    Element(rawValue: String(name))
                }

                return Set(elements)
            },
            encode: { elements in
                let names = elements.map(\.rawValue).sorted()
                return names.isEmpty ? nil : names.joined(separator: ",")
            }
        )
    }
}

extension SettingKey where Value: RawRepresentable, Value.RawValue == String {
    init(
        _ key: Setting.Key,
        default defaultValue: Value
    ) {
        self.init(
            key,
            default: defaultValue,
            decode: { Value(rawValue: $0) },
            encode: { $0.rawValue }
        )
    }
}

extension SettingKey where Value == Bool {
    init(flag key: Setting.Key) {
        self.init(
            key,
            default: false,
            decode: { $0 == "true" },
            encode: { $0 ? "true" : nil }
        )
    }

    init(switch key: Setting.Key) {
        self.init(
            key,
            default: true,
            decode: { $0 != "false" },
            encode: { $0 ? nil : "false" }
        )
    }
}
