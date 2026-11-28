import Foundation

public enum DeviceName {
    public static let current = name(ofModel: modelIdentifier)

    private static let modelNames = [
        "iPhone12,1": "iPhone 11",
        "iPhone12,3": "iPhone 11 Pro",
        "iPhone12,5": "iPhone 11 Pro Max",
        "iPhone12,8": "iPhone SE（第2世代）",
        "iPhone13,1": "iPhone 12 mini",
        "iPhone13,2": "iPhone 12",
        "iPhone13,3": "iPhone 12 Pro",
        "iPhone13,4": "iPhone 12 Pro Max",
        "iPhone14,2": "iPhone 13 Pro",
        "iPhone14,3": "iPhone 13 Pro Max",
        "iPhone14,4": "iPhone 13 mini",
        "iPhone14,5": "iPhone 13",
        "iPhone14,6": "iPhone SE（第3世代）",
        "iPhone14,7": "iPhone 14",
        "iPhone14,8": "iPhone 14 Plus",
        "iPhone15,2": "iPhone 14 Pro",
        "iPhone15,3": "iPhone 14 Pro Max",
        "iPhone15,4": "iPhone 15",
        "iPhone15,5": "iPhone 15 Plus",
        "iPhone16,1": "iPhone 15 Pro",
        "iPhone16,2": "iPhone 15 Pro Max",
        "iPhone17,1": "iPhone 16 Pro",
        "iPhone17,2": "iPhone 16 Pro Max",
        "iPhone17,3": "iPhone 16",
        "iPhone17,4": "iPhone 16 Plus",
        "iPhone17,5": "iPhone 16e",
        "iPhone18,1": "iPhone 17 Pro",
        "iPhone18,2": "iPhone 17 Pro Max",
        "iPhone18,3": "iPhone 17",
        "iPhone18,4": "iPhone Air",
        "iPhone18,5": "iPhone 17e",
        "iPad8,1": "iPad Pro 11インチ（第1世代）",
        "iPad8,2": "iPad Pro 11インチ（第1世代）",
        "iPad8,3": "iPad Pro 11インチ（第1世代）",
        "iPad8,4": "iPad Pro 11インチ（第1世代）",
        "iPad8,5": "iPad Pro 12.9インチ（第3世代）",
        "iPad8,6": "iPad Pro 12.9インチ（第3世代）",
        "iPad8,7": "iPad Pro 12.9インチ（第3世代）",
        "iPad8,8": "iPad Pro 12.9インチ（第3世代）",
        "iPad8,9": "iPad Pro 11インチ（第2世代）",
        "iPad8,10": "iPad Pro 11インチ（第2世代）",
        "iPad8,11": "iPad Pro 12.9インチ（第4世代）",
        "iPad8,12": "iPad Pro 12.9インチ（第4世代）",
        "iPad11,1": "iPad mini（第5世代）",
        "iPad11,2": "iPad mini（第5世代）",
        "iPad11,3": "iPad Air（第3世代）",
        "iPad11,4": "iPad Air（第3世代）",
        "iPad11,6": "iPad（第8世代）",
        "iPad11,7": "iPad（第8世代）",
        "iPad12,1": "iPad（第9世代）",
        "iPad12,2": "iPad（第9世代）",
        "iPad13,1": "iPad Air（第4世代）",
        "iPad13,2": "iPad Air（第4世代）",
        "iPad13,4": "iPad Pro 11インチ（第3世代）",
        "iPad13,5": "iPad Pro 11インチ（第3世代）",
        "iPad13,6": "iPad Pro 11インチ（第3世代）",
        "iPad13,7": "iPad Pro 11インチ（第3世代）",
        "iPad13,8": "iPad Pro 12.9インチ（第5世代）",
        "iPad13,9": "iPad Pro 12.9インチ（第5世代）",
        "iPad13,10": "iPad Pro 12.9インチ（第5世代）",
        "iPad13,11": "iPad Pro 12.9インチ（第5世代）",
        "iPad13,16": "iPad Air（第5世代）",
        "iPad13,17": "iPad Air（第5世代）",
        "iPad13,18": "iPad（第10世代）",
        "iPad13,19": "iPad（第10世代）",
        "iPad14,1": "iPad mini（第6世代）",
        "iPad14,2": "iPad mini（第6世代）",
        "iPad14,3": "iPad Pro 11インチ（第4世代）",
        "iPad14,4": "iPad Pro 11インチ（第4世代）",
        "iPad14,5": "iPad Pro 12.9インチ（第6世代）",
        "iPad14,6": "iPad Pro 12.9インチ（第6世代）",
        "iPad14,8": "iPad Air 11インチ（M2）",
        "iPad14,9": "iPad Air 11インチ（M2）",
        "iPad14,10": "iPad Air 13インチ（M2）",
        "iPad14,11": "iPad Air 13インチ（M2）",
        "iPad15,3": "iPad Air 11インチ（M3）",
        "iPad15,4": "iPad Air 11インチ（M3）",
        "iPad15,5": "iPad Air 13インチ（M3）",
        "iPad15,6": "iPad Air 13インチ（M3）",
        "iPad15,7": "iPad（A16）",
        "iPad15,8": "iPad（A16）",
        "iPad16,1": "iPad mini（A17 Pro）",
        "iPad16,2": "iPad mini（A17 Pro）",
        "iPad16,3": "iPad Pro 11インチ（M4）",
        "iPad16,4": "iPad Pro 11インチ（M4）",
        "iPad16,5": "iPad Pro 13インチ（M4）",
        "iPad16,6": "iPad Pro 13インチ（M4）"
    ]

    public static var modelIdentifier: String {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulated
        }

        var info = utsname()

        uname(&info)

        return withUnsafeBytes(of: &info.machine) { bytes in
            String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
        }
    }

    public static var modelName: String {
        modelName(ofModel: modelIdentifier)
    }

    static func name(ofModel model: String) -> String {
        model.hasPrefix("iPad") ? "iPad" : "iPhone"
    }

    static func modelName(ofModel model: String) -> String {
        modelNames[model] ?? model
    }
}
