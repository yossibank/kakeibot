import Core
import FeatureModels
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
    struct Fields: ScreenEditable {
        var version: String
    }

    @MainActor
    @Observable
    final class State {
        var fields: Fields

        init(version: String) {
            self.fields = Fields(version: version)
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

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }
    }
}

extension WhatsNewModel.Output {
    var release: WhatsNewRelease? {
        let releases = WhatsNewRelease.all
        return releases.first { $0.version == state.fields.version } ?? releases.first
    }

    func isNew(_ release: WhatsNewRelease) -> Bool {
        AppVersion.isNewer(release.version, than: input.seenVersion)
    }
}

extension WhatsNewModel.State {
    func choose(_ version: String) {
        guard version != fields.version else {
            return
        }

        fields.version = version
    }
}
