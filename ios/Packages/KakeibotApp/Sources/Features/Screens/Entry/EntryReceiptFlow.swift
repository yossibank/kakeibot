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

    enum Outcome: Equatable {
        case unread
        case read(itemCount: Int, hasAmount: Bool)
    }

    static let offerFeature = "4 回目からのレシートの読み取り"
    static let unreadMessage = "レシートを読めませんでした。明るい所で撮り直してください"
    static let totalMessage = "レシートの合計を読みました"

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
    ) async -> Outcome {
        step = .reading

        let reading = await read(pages)

        step = nil

        guard !reading.isEmpty else {
            model.errorNotice.show(Self.unreadMessage)
            return .unread
        }

        let hasAmount = await model.apply(reading)

        if reading.items.isEmpty, hasAmount {
            model.errorNotice.inform(Self.totalMessage)
        }

        return .read(itemCount: reading.items.count, hasAmount: hasAmount)
    }
}
