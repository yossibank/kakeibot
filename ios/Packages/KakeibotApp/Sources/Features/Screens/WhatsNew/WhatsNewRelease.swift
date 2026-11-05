public struct WhatsNewRelease: Identifiable, Sendable {
    let version: String
    let month: String
    let features: [Feature]

    public var id: String {
        version
    }
}

public extension WhatsNewRelease {
    enum Action: Hashable, Sendable {
        case entry
        case assets
        case setup(SetupItem)
    }

    static var latestVersion: String {
        all.first?.version ?? "0"
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

        var id: String {
            title
        }
    }

    struct Step: Hashable, Sendable {
        let scene: WhatsNewScene.Kind
        let caption: String
    }

    static let all = [
        v1_2_0,
        v1_1_0
    ]
}
