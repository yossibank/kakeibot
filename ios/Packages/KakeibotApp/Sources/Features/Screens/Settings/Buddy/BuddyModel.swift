import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class BuddyModel {
    public var customName = ""

    public private(set) var buddy: Buddy? = .dial

    public internal(set) var errorNotice = ErrorNotice()

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension BuddyModel {
    var profile: BuddyProfile {
        BuddyProfile(buddy: buddy, customName: customName)
    }

    func load() async {
        do {
            let profile = try await database.buddyProfile()
            buddy = profile.buddy
            customName = profile.customName
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func choose(_ buddy: Buddy?) async {
        let previous = self.buddy
        self.buddy = buddy

        do {
            try await database.setSetting(.buddy, to: buddy)
        } catch {
            self.buddy = previous
            errorNotice.show(Self.saveFailedMessage)
        }
    }

    func saveName() async {
        let name = customName.trimmingCharacters(in: .whitespaces)

        do {
            try await database.setSetting(.buddyName, to: name)
        } catch {
            errorNotice.show(Self.saveFailedMessage)
        }
    }
}

private extension BuddyModel {
    static let loadFailedMessage = "設定を読めませんでした"
    static let saveFailedMessage = "設定を保存できませんでした"
}
