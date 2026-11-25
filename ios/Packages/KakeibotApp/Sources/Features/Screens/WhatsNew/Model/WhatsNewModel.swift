import Core
import Observation

@MainActor
@Observable
final class WhatsNewModel {
    let state: State
    let input: Input
    let output: Output

    init(
        seenVersion: String?,
        version: String
    ) {
        let state = State(version: version)
        let input = Input(seenVersion: seenVersion)

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
    }
}

extension WhatsNewModel {
    @MainActor
    @Observable
    final class State {
        private(set) var version: String

        init(version: String) {
            self.version = version
        }

        func choose(_ version: String) {
            guard version != self.version else {
                return
            }

            self.version = version
        }
    }

    @MainActor
    @Observable
    final class Input {
        let seenVersion: String?

        init(seenVersion: String?) {
            self.seenVersion = seenVersion
        }
    }

    @MainActor
    final class Output {
        let input: Input
        let state: State

        var release: WhatsNewRelease? {
            let releases = WhatsNewRelease.all
            return releases.first { $0.version == state.version } ?? releases.first
        }

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }

        func isNew(_ release: WhatsNewRelease) -> Bool {
            AppVersion.isNewer(release.version, than: input.seenVersion)
        }
    }
}
