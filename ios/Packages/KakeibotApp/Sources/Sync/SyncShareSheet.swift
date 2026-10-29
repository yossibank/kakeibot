import CloudKit
import UIKit

@MainActor
public final class SyncShareSheet: NSObject {
    private static var shown: SyncShareSheet?

    private var isStopped = false

    private let title: String
    private let onStop: @MainActor () async -> Void

    private init(
        title: String,
        onStop: @escaping @MainActor () async -> Void
    ) {
        self.title = title
        self.onStop = onStop
    }
}

public extension SyncShareSheet {
    static func present(
        _ share: CKShare,
        title: String,
        container: CKContainer = CKContainer(identifier: SyncEngine.containerIdentifier),
        onStop: @escaping @MainActor () async -> Void
    ) {
        guard let presenter = topViewController() else {
            return
        }

        let sheet = SyncShareSheet(title: title, onStop: onStop)
        let controller = ShareController(share: share, container: container)

        controller.availablePermissions = [.allowPrivate, .allowReadWrite]
        controller.delegate = sheet
        controller.onDismiss = { [weak sheet, weak controller] in
            sheet?.close(controller?.share)
        }

        shown = sheet
        presenter.present(controller, animated: true)
    }
}

private extension SyncShareSheet {
    final class ShareController: UICloudSharingController {
        var onDismiss: (() -> Void)?

        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)

            if isBeingDismissed {
                onDismiss?()
            }
        }
    }

    static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }

        var top = scene?.keyWindow?.rootViewController

        while let presented = top?.presentedViewController {
            top = presented
        }

        return top
    }

    func close(_ share: CKShare?) {
        let hasGuests = share?.participants.contains { $0.role != .owner } ?? false

        guard !hasGuests else {
            Self.shown = nil
            return
        }

        stop()
    }

    func stop() {
        Self.shown = nil

        guard !isStopped else {
            return
        }

        isStopped = true

        Task {
            await onStop()
        }
    }
}

extension SyncShareSheet: UICloudSharingControllerDelegate {
    public func cloudSharingController(
        _ csc: UICloudSharingController,
        failedToSaveShareWithError error: any Error
    ) {}

    public func itemTitle(for csc: UICloudSharingController) -> String? {
        title
    }

    public func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        stop()
    }
}
