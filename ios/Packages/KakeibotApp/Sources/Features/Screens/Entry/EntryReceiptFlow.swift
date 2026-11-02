import Core
import CoreGraphics
import Observation

@MainActor
@Observable
final class EntryReceiptFlow {
    private(set) var step: Step?
    private(set) var offer: String?

    private let read: ([CGImage]) async -> ReceiptReading

    init(read: @escaping ([CGImage]) async -> ReceiptReading = EntryReceiptReader.read) {
        self.read = read
    }
}

extension EntryReceiptFlow {
    enum Step: Hashable {
        case guide
        case camera
        case reading
    }

    static let offerFeature = "4 回目からのレシートの読み取り"
    static let unreadMessage = "レシートを読めませんでした。明るい所で撮り直してください"

    var isScanning: Bool {
        step == .camera
    }

    func start(
        for model: EntryModel,
        isPro: Bool
    ) {
        guard model.canReadReceipt(isPro: isPro) else {
            offer = Self.offerFeature
            return
        }

        offer = nil
        step = model.showsReceiptGuide ? .guide : .camera
    }

    func confirmGuide() {
        step = .camera
    }

    func cancel() {
        step = nil
    }

    func closeOffer() {
        offer = nil
    }

    func scan(
        _ pages: [CGImage],
        into model: EntryModel
    ) async -> Bool {
        step = .reading

        let reading = await read(pages)

        step = nil

        guard !reading.isEmpty else {
            model.errorNotice.show(Self.unreadMessage)
            return false
        }

        await model.apply(reading)

        return model.amount > 0
    }
}
