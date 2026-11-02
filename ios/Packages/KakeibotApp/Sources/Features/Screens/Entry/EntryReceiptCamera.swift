import SwiftUI
import VisionKit

struct EntryReceiptCamera: UIViewControllerRepresentable {
    let onScan: ([CGImage]) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let camera = VNDocumentCameraViewController()
        camera.delegate = context.coordinator
        return camera
    }

    func updateUIViewController(
        _ camera: VNDocumentCameraViewController,
        context: Context
    ) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, onCancel: onCancel)
    }
}

extension EntryReceiptCamera {
    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScan: ([CGImage]) -> Void
        let onCancel: () -> Void

        init(
            onScan: @escaping ([CGImage]) -> Void,
            onCancel: @escaping () -> Void
        ) {
            self.onScan = onScan
            self.onCancel = onCancel
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            let pages = (0..<scan.pageCount).compactMap { index in
                scan.imageOfPage(at: index).cgImage
            }

            onScan(pages)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: any Error
        ) {
            onCancel()
        }
    }
}

public extension EnvironmentValues {
    @Entry var canScanReceipt = false
}
