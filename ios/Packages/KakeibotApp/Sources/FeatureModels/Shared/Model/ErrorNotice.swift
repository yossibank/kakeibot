import DesignSystem
import Observation

@MainActor
@Observable
public final class ErrorNotice {
    public private(set) var message: String?
    public private(set) var tone: NoticeBanner.Tone = .error
    public private(set) var count = 0

    @ObservationIgnored private var timer: Task<Void, Never>?

    @ObservationIgnored private let wait: ScreenWait

    public init(wait: ScreenWait) {
        self.wait = wait
    }
}

public extension ErrorNotice {
    nonisolated static var duration: Duration {
        .seconds(6)
    }

    func show(_ message: String) {
        present(message, tone: .error)
    }

    func inform(_ message: String) {
        present(message, tone: .info)
    }

    func clear() {
        timer?.cancel()
        timer = nil
        message = nil
    }
}

private extension ErrorNotice {
    func present(
        _ message: String,
        tone: NoticeBanner.Tone
    ) {
        self.message = message
        self.tone = tone
        count += 1

        let count = count

        timer?.cancel()

        timer = wait.after(Self.duration) { [weak self] in
            guard let self, self.count == count else {
                return
            }

            clear()
        }
    }
}
