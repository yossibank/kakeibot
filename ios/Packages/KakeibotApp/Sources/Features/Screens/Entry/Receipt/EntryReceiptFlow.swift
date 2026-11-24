import Core
import CoreGraphics
import Observation

@MainActor
@Observable
final class EntryReceiptFlow {
    let state: State
    let output: Output
    let dependencies: Dependencies

    init(
        read: @escaping ([CGImage]) async -> ReceiptReading = EntryReceiptReader.read,
        prepare: @escaping @MainActor () -> Void = EntryReceiptReader.prepare
    ) {
        let state = State()

        self.state = state
        self.output = Output(state: state)
        self.dependencies = Dependencies(read: read, prepare: prepare)
    }
}

extension EntryReceiptFlow {
    enum Step: Hashable {
        case guide
        case camera
        case reading
    }

    enum Outcome: Equatable {
        case unread
        case read(itemCount: Int, hasAmount: Bool)
    }

    @MainActor
    @Observable
    final class State {
        var hidesGuide = false

        private(set) var step: Step?
        private(set) var offer: String?

        func showOffer(_ feature: String) {
            offer = feature
        }

        func closeOffer() {
            offer = nil
        }

        func open(showsGuide: Bool) {
            offer = nil
            hidesGuide = false
            step = showsGuide ? .guide : .camera
        }

        func openCamera() {
            step = .camera
        }

        func startReading() {
            step = .reading
        }

        func close() {
            step = nil
        }
    }

    @MainActor
    final class Output {
        let state: State

        init(state: State) {
            self.state = state
        }
    }

    struct Dependencies {
        let read: ([CGImage]) async -> ReceiptReading
        let prepare: @MainActor () -> Void
    }

    static let offerFeature = "4 回目からのレシートの読み取り"
    static let unreadMessage = "レシートを読めませんでした。明るい所で撮り直してください"
    static let totalMessage = "レシートの合計を読みました"

    func start(
        for model: EntryModel,
        isPro: Bool
    ) {
        guard model.output.canReadReceipt(isPro: isPro) else {
            state.showOffer(Self.offerFeature)
            return
        }

        dependencies.prepare()
        state.open(showsGuide: model.output.showsReceiptGuide)
    }

    func confirmGuide() {
        dependencies.prepare()
        state.openCamera()
    }

    func cancel() {
        state.close()
    }

    func saveGuideChoice(for model: EntryModel) async {
        guard state.hidesGuide else {
            return
        }

        await model.hideReceiptGuide()
    }

    func closeOffer() {
        state.closeOffer()
    }

    func scan(
        _ pages: [CGImage],
        into model: EntryModel
    ) async -> Outcome {
        state.startReading()

        let reading = await dependencies.read(pages)

        state.close()

        guard !reading.isEmpty else {
            model.state.errorNotice.show(Self.unreadMessage)
            return .unread
        }

        let hasAmount = await model.apply(reading)

        if reading.items.isEmpty, hasAmount {
            model.state.errorNotice.inform(Self.totalMessage)
        }

        return .read(itemCount: reading.items.count, hasAmount: hasAmount)
    }
}

extension EntryReceiptFlow.Output {
    var isScanning: Bool {
        state.step == .camera
    }
}
