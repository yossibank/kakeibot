import CloudKit
import Features

extension SyncParticipant {
    init?(_ participant: CKShare.Participant) {
        let state: State? = switch (participant.role, participant.acceptanceStatus) {
        case (.owner, _): .owner
        case (_, .accepted): .joined
        case (_, .pending): .invited
        default: nil
        }

        guard let state else {
            return nil
        }

        self.init(name: Self.name(of: participant.userIdentity), state: state)
    }
}

private extension SyncParticipant {
    static func name(of identity: CKUserIdentity) -> String {
        if let components = identity.nameComponents {
            let name = components.formatted()

            if !name.isEmpty {
                return name
            }
        }

        let lookup = identity.lookupInfo
        return lookup?.emailAddress ?? lookup?.phoneNumber ?? ""
    }
}
