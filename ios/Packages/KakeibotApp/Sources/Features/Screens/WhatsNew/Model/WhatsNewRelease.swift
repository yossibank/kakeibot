import FeatureModels

public struct WhatsNewRelease: Identifiable, Sendable {
    let version: String
    let month: String
    let features: [Feature]
}

public extension WhatsNewRelease {
    enum Action: Hashable, Sendable {
        case entry
        case records
        case review
        case assets
        case setup(SetupItem)
    }
}

extension WhatsNewRelease {
    struct Feature: Identifiable, Sendable {
        let systemImage: String
        let title: String
        let shortTitle: String
        let lead: String
        let points: [String]

        var note: String?

        let steps: [Step]
        let action: Action?
        let actionTitle: String
    }

    struct Step: Hashable, Sendable {
        let scene: WhatsNewScene.Kind
        let caption: String
    }
}

public extension WhatsNewRelease {
    static var latestVersion: String {
        all.first?.version ?? "0"
    }

    var id: String {
        version
    }
}

extension WhatsNewRelease {
    static let all = [
        v1_9_0,
        v1_8_0,
        v1_7_0,
        v1_6_0,
        v1_5_0,
        v1_4_0,
        v1_3_0,
        v1_2_0,
        v1_1_0
    ]
}

extension WhatsNewRelease.Feature {
    var id: String {
        title
    }
}
